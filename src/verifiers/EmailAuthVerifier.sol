// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CircuitUtils } from "../utils/CircuitUtils.sol";
import { IGroth16Verifier } from "../interfaces/IGroth16Verifier.sol";

struct EmailAuthProof {
    DecodedFields fields;
    bytes proof;
}

struct DecodedFields {
    string domainName;
    bytes32 publicKeyHash;
    bytes32 emailNullifier;
    uint256 timestamp;
    string maskedCommand;
    bytes32 accountSalt;
    bool isCodeExist;
    bytes miscellaneousData;
    string emailAddress;
}

/**
 * @title EmailAuthVerifier
 * @notice This abstract contract provides the core logic for verifying EmailAuth circuit  proofs.
 * @dev It defines the public signals' structure and offers internal functions to pack, unpack, and verify them
 * against a Groth16 proof. The public signals are laid out in a fixed 60-element array, with each segment
 * corresponding to a specific piece of data extracted from the email.
 *
 * The public signals array (`pubSignals`) is structured as follows:
 *       ----------------------------------------------------------------------------------------------------------
 *      | Range   | #Fields | Field Name          | Description                                                    |
 *      |---------|---------|---------------------|----------------------------------------------------------------|
 *      | 0-8     | 9       | domainName          | Packed string of the sender's domain name.                     |
 *      | 9       | 1       | publicKeyHash       | The hash of the DKIM RSA public key.                           |
 *      | 10      | 1       | emailNullifier      | A unique identifier to prevent replay attacks.                 |
 *      | 11      | 1       | timestamp           | The email's timestamp. Defaults to 0 if not available.         |
 *      | 12-31   | 20      | maskedCommand       | The packed string of the command extracted from the email.     |
 *      | 32      | 1       | accountSalt         | An optional salt for added security.                           |
 *      | 33      | 1       | isCodeExist         | A boolean flag indicating if a verification code is present.   |
 *      | 34-50   | 17      | miscellaneousData   | Auxiliary data, typically the decomposed DKIM public key.      |
 *      | 51-59   | 9       | emailAddress        | The packed string of the sender's full email address.          |
 *       ----------------------------------------------------------------------------------------------------------
 */
abstract contract EmailAuthVerifier {
    /// @notice The order of the BN128 elliptic curve used in the ZK proofs
    /// @dev All field elements in proofs must be less than this value
    uint256 public constant Q =
        21_888_242_871_839_275_222_246_405_745_257_275_088_696_311_157_297_823_662_689_037_894_645_226_208_583;

    // #1: domain_name CEIL(255 bytes / 31 bytes per field) = 9 fields -> idx 0-8
    uint256 public constant DOMAIN_NAME_OFFSET = 0;
    uint256 public constant DOMAIN_NAME_SIZE = 255;
    // #2: public_key_hash 32 bytes -> 1 field -> idx 9
    uint256 public constant PUBLIC_KEY_HASH_OFFSET = 9;
    // #3: email_nullifier 32 bytes -> 1 field -> idx 10
    uint256 public constant EMAIL_NULLIFIER_OFFSET = 10;
    // #4: timestamp 32 bytes -> 1 field -> idx 11
    uint256 public constant TIMESTAMP_OFFSET = 11;
    // #5: masked_command CEIL(605 bytes / 31 bytes per field) = 20 fields -> idx 12-31
    uint256 public constant MASKED_COMMAND_OFFSET = 12;
    uint256 public constant MASKED_COMMAND_SIZE = 605;
    // #6: account_salt 32 bytes -> 1 field -> idx 32
    uint256 public constant ACCOUNT_SALT_OFFSET = 32;
    // #7: is_code_exist 1 byte -> 1 field -> idx 33
    uint256 public constant IS_CODE_EXIST_OFFSET = 33;
    // #8: pubkey -> 17 fields -> idx 34-50
    uint256 public constant MISCELLANEOUS_DATA_OFFSET = 34;
    // #9: email_address CEIL(256 bytes / 31 bytes per field) = 9 fields -> idx 51-59
    uint256 public constant EMAIL_ADDRESS_OFFSET = 51;
    uint256 public constant EMAIL_ADDRESS_SIZE = 256;

    /**
     * @notice Verifies the validity of an EmailAuthProof
     * @param emailProof The EmailAuthProof struct containing the proof and decoded fields
     * @param groth16Verifier The address of the Groth16Verifier contract
     * @return isValid True if the proof is valid, false otherwise
     */
    function _isValidEmailProof(
        EmailAuthProof memory emailProof,
        address groth16Verifier
    )
        internal
        view
        returns (bool isValid)
    {
        // decode the proof
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(emailProof.proof, (uint256[2], uint256[2][2], uint256[2]));

        // check if all values are less than Q (max value of bn128 curve)
        bool validFieldElements = (
            pA[0] < Q && pA[1] < Q && pB[0][0] < Q && pB[0][1] < Q && pB[1][0] < Q && pB[1][1] < Q && pC[0] < Q
                && pC[1] < Q
        );

        if (!validFieldElements) {
            return false;
        }

        uint256[60] memory pubSignals = _packPubSignals(emailProof.fields);

        // verify the proof
        bool validProof = IGroth16Verifier(groth16Verifier).verifyProof(pA, pB, pC, pubSignals);

        return validProof;
    }

    /**
     * @notice Unpacks the public signals and proof into a DecodedFields struct
     * @param pubSignals Array of public signals from the ZK proof
     * @return decodedFields The decoded fields struct, with each field extracted from the
     * pubSignals
     */
    function _unpackPubSignals(uint256[] calldata pubSignals)
        internal
        pure
        returns (DecodedFields memory decodedFields)
    {
        if (pubSignals.length != 60) revert CircuitUtils.InvalidPubSignalsLength();

        decodedFields.domainName = CircuitUtils.unpackString(pubSignals, DOMAIN_NAME_OFFSET, DOMAIN_NAME_SIZE);
        decodedFields.publicKeyHash = CircuitUtils.unpackBytes32(pubSignals, PUBLIC_KEY_HASH_OFFSET);
        decodedFields.emailNullifier = CircuitUtils.unpackBytes32(pubSignals, EMAIL_NULLIFIER_OFFSET);
        decodedFields.timestamp = CircuitUtils.unpackUint256(pubSignals, TIMESTAMP_OFFSET);
        decodedFields.maskedCommand = CircuitUtils.unpackString(pubSignals, MASKED_COMMAND_OFFSET, MASKED_COMMAND_SIZE);
        decodedFields.accountSalt = CircuitUtils.unpackBytes32(pubSignals, ACCOUNT_SALT_OFFSET);
        decodedFields.isCodeExist = CircuitUtils.unpackBool(pubSignals, IS_CODE_EXIST_OFFSET);
        decodedFields.miscellaneousData = CircuitUtils.unpackMiscellaneousData(pubSignals, MISCELLANEOUS_DATA_OFFSET);
        decodedFields.emailAddress = CircuitUtils.unpackString(pubSignals, EMAIL_ADDRESS_OFFSET, EMAIL_ADDRESS_SIZE);

        return decodedFields;
    }

    /**
     * @notice Packs the decoded fields into the public signals array
     * @param decodedFields The decoded fields struct
     * @return pubSignals The packed public signals array
     */
    function _packPubSignals(DecodedFields memory decodedFields)
        internal
        pure
        returns (uint256[60] memory pubSignals)
    {
        uint256[][] memory fields = new uint256[][](9);
        fields[0] = CircuitUtils.packString(decodedFields.domainName, DOMAIN_NAME_SIZE);
        fields[1] = CircuitUtils.packBytes32(decodedFields.publicKeyHash);
        fields[2] = CircuitUtils.packBytes32(decodedFields.emailNullifier);
        fields[3] = CircuitUtils.packUint256(decodedFields.timestamp);
        fields[4] = CircuitUtils.packString(decodedFields.maskedCommand, MASKED_COMMAND_SIZE);
        fields[5] = CircuitUtils.packBytes32(decodedFields.accountSalt);
        fields[6] = CircuitUtils.packBool(decodedFields.isCodeExist);
        fields[7] = CircuitUtils.packPubKey(decodedFields.miscellaneousData);
        fields[8] = CircuitUtils.packString(decodedFields.emailAddress, EMAIL_ADDRESS_SIZE);
        pubSignals = CircuitUtils.flattenFields(fields);

        return pubSignals;
    }
}
