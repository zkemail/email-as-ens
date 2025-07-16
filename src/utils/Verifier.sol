// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CircuitUtils } from "./CircuitUtils.sol";
import { IGroth16Verifier } from "../interfaces/IGroth16Verifier.sol";

/**
 * @notice Enum representing the indices of command parameters in the command template
 * @dev Used to specify which parameter to extract from the command string
 * @param OWNER = 0
 * @param RESOLVER = 1
 */
enum CommandParamIndex {
    OWNER,
    RESOLVER
}

/**
 * @title ProveAndClaimCommand
 * @notice A struct representing a zero-knowledge proof command for claiming ENS names via email verification
 * @dev This struct contains all the necessary data for proving email ownership and claiming corresponding ENS names.
 *      It includes the email details, cryptographic proofs, and metadata required for verification.
 */
struct ProveAndClaimCommand {
    /// @notice The domain part of the email address (e.g., "gmail.com")
    /// @dev Used to identify the email provider and corresponding DKIM public key for verification
    string domain;
    /// @notice The complete email address (e.g., "user@gmail.com")
    /// @dev This is the email address being claimed, which will correspond to the ENS subdomain
    string email;
    /// @notice The resolver ENS name for the ENS name
    /// @dev This ENS name is used to resolve the ENS name to an Ethereum address
    string resolver;
    /// @notice The parts of the email address dot separated (e.g., ["user", "gmail", "com"])
    /// @dev Used to verify the email address
    string[] emailParts;
    /// @notice The Ethereum address that will own the claimed ENS name
    /// @dev This address becomes the owner of the ENS name derived from the email address
    address owner;
    /// @notice Hash of the RSA public key used for DKIM signature verification
    /// @dev This hash uniquely identifies the DKIM public key and ensures the email's authenticity
    bytes32 dkimSignerHash;
    /// @notice A unique identifier used to prevent replay attacks
    /// @dev This nullifier ensures that each email can only be used once for claiming an ENS name
    bytes32 nullifier;
    /// @notice The timestamp from the email header, or 0 if not supported
    /// @dev Some email providers (like Outlook) don't sign timestamps, so this field may be 0
    uint256 timestamp;
    /// @notice Account salt for additional privacy.
    /// @dev Used to hide email address on-chain. Which is not relavant here.
    bytes32 accountSalt;
    /// @notice Indicates whether the verification code is embedded in the email
    /// @dev Used in proof verification
    bool isCodeEmbedded;
    /// @notice Additional data for future compatibility and flexibility
    /// @dev This field can contain DNSSEC proof data, additional verification parameters,
    ///      or any other data required by specific verifier implementations. Can be 0x0 if unused.
    bytes miscellaneousData;
    /// @notice The zero-knowledge proof that validates all fields in this struct
    /// @dev Contains the proof compatible with verifier
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
    bytes pubKey;
    string emailAddress;
}

/**
 * @title ProveAndClaimCommandVerifier
 * @notice Verifies zero-knowledge proofs for email-based ENS name claiming
 * @dev This contract validates ProveAndClaimCommand structs by verifying their ZK proof.
 *      It ensures that users can cryptographically prove email ownership.
 *
 *      The verification process includes:
 *      1. Decoding the command and extracting the ZK proof
 *      2. Building public signals from the command data
 *      3. Verifying the proof against the expected circuit constraints
 *      4. TODO: verifying DKIM oracle proofs for additional security
 */
contract ProveAndClaimCommandVerifier {
    using Bytes for bytes;
    using Strings for string;
    using CircuitUtils for bytes;

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
    uint256 public constant PUBKEY_OFFSET = 34;
    // #9: email_address CEIL(256 bytes / 31 bytes per field) = 9 fields -> idx 51-59
    uint256 public constant EMAIL_ADDRESS_OFFSET = 51;
    uint256 public constant EMAIL_ADDRESS_SIZE = 256;

    /// @notice The address of the deployed Groth16Verifier contract
    /// @dev The Groth16 verifier must be compatible with the specific circuit used for email verification.
    ///      This address is immutable to prevent unauthorized changes to the verification logic.
    address public immutable GORTH16_VERIFIER;

    /**
     * @notice Initializes the verifier with a Groth16 verifier contract
     * @param _groth16Verifier The address of the deployed Groth16Verifier contract
     */
    constructor(address _groth16Verifier) {
        GORTH16_VERIFIER = _groth16Verifier;
    }

    /**
     * @notice Verifies the validity of a ProveAndClaimCommand
     * @param data The ABI-encoded ProveAndClaimCommand struct to verify
     * @return True if the command and its proof are valid, false otherwise
     * @dev This function performs verification:
     *      1. Decoding the command from the provided data
     *      2. Extracting and validating the ZK proof components
     *      3. Ensuring all proof elements are within the valid field range
     *      4. Building the public signals array from command data
     *      5. Verifying the proof against the Groth16 verifier
     *
     *      The function will return false if:
     *      - The proof components are not valid field elements
     *      - The zk proof verification fails
     *      - Any step in the verification process encounters an error (note to reviewer: how to make sure?)
     */
    function isValid(bytes memory data) external view returns (bool) {
        // decode the data into a ProveAndClaimCommand struct
        ProveAndClaimCommand memory command = abi.decode(data, (ProveAndClaimCommand));

        // decode the proof
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(command.proof, (uint256[2], uint256[2][2], uint256[2]));

        // check if all values are less than Q (max value of bn128 curve)
        if (
            !(
                pA[0] < Q && pA[1] < Q && pB[0][0] < Q && pB[0][1] < Q && pB[1][0] < Q && pB[1][1] < Q && pC[0] < Q
                    && pC[1] < Q
            )
        ) {
            return false;
        }

        if (!CircuitUtils.verifyEmailParts(command.emailParts, command.email)) {
            return false;
        }

        // build the public signals
        uint256[60] memory pubSignals = _buildPubSignals(command);

        // verify the proof
        return IGroth16Verifier(GORTH16_VERIFIER).verifyProof(pA, pB, pC, pubSignals);

        // todo: verify DKIM oracle proof
    }

    /**
     * @notice Unpacks the public signals and proof into a ProveAndClaimCommand struct and encodes it into bytes
     * @param pubSignals Array of public signals from the ZK proof
     * @param proof The zero-knowledge proof bytes
     * @return encodedCommand ABI-encoded ProveAndClaimCommand struct in bytes
     * @dev This function allows off-chain encoding of proof parameters to avoid potentially
     *      expensive on-chain encoding. The backend can call this as a pure function
     *      to get the properly formatted proof data for on-chain submission.
     *
     *      The pubSignals array should contain 60 elements in the same order
     *      as defined in _buildPubSignals:
     *       -------------------------------------------------------------------------------------
     *      | Range | #fields | Field name      | Description                                     |
     *      |-------------------------------------------------------------------------------------|
     *      | 0-8   | 9       | domain_name     | packed representation of the email domain       |
     *      | 9     | 1       | public_key_hash | hash of the DKIM RSA public key                 |
     *      | 10    | 1       | email_nullifier | unique identifier preventing replay attacks     |
     *      | 11    | 1       | timestamp       | email timestamp, 0 if not supported             |
     *      | 12-31 | 20      | masked_command  | packed representation of the expected command   |
     *      | 32    | 1       | account_salt    | additional randomness for security              |
     *      | 33    | 1       | is_code_exist   | boolean indicating embedded verification code   |
     *      | 34-50 | 17      | pubkey          | decomposed RSA public key components            |
     *      | 51-59 | 9       | email_address   | packed representation of the full email address |
     *       -------------------------------------------------------------------------------------
     */
    function encode(
        uint256[] calldata pubSignals,
        bytes calldata proof
    )
        public
        pure
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildProveAndClaimCommand(pubSignals, proof));
    }

    /**
     * @notice Builds the public signals required for proof verification
     * @param command The ProveAndClaimCommand struct containing the necessary data
     * @return pubSignals An array of 60 uint256 values representing the public signals
     * @dev The public signals are structured as follows (in order, totaling 60 fields):
     *       -------------------------------------------------------------------------------------
     *      | Range | #fields | Field name      | Description                                     |
     *      |-------------------------------------------------------------------------------------|
     *      | 0-8   | 9       | domain_name     | packed representation of the email domain       |
     *      | 9     | 1       | public_key_hash | hash of the DKIM RSA public key                 |
     *      | 10    | 1       | email_nullifier | unique identifier preventing replay attacks     |
     *      | 11    | 1       | timestamp       | email timestamp, 0 if not supported             |
     *      | 12-31 | 20      | masked_command  | packed representation of the expected command   |
     *      | 32    | 1       | account_salt    | additional randomness for security              |
     *      | 33    | 1       | is_code_exist   | boolean indicating embedded verification code   |
     *      | 34-50 | 17      | pubkey          | decomposed RSA public key components            |
     *      | 51-59 | 9       | email_address   | packed representation of the full email address |
     *       -------------------------------------------------------------------------------------
     *
     *      All string data (domain, email, command) is packed into field elements using a specific
     *      encoding scheme that packs 31 bytes per field element for efficiency.
     *
     *      The expected command format is: "Claim ENS name for address {ethAddr}"
     *      where {ethAddr} is replaced with the actual Ethereum address from the command.
     */
    function _buildPubSignals(ProveAndClaimCommand memory command)
        internal
        pure
        returns (uint256[60] memory pubSignals)
    {
        pubSignals = _packPubSignals(
            DecodedFields({
                domainName: command.domain,
                publicKeyHash: command.dkimSignerHash,
                emailNullifier: command.nullifier,
                timestamp: command.timestamp,
                maskedCommand: _getMaskedCommand(command),
                accountSalt: command.accountSalt,
                isCodeExist: command.isCodeEmbedded,
                pubKey: command.miscellaneousData,
                emailAddress: command.email
            })
        );
    }

    /**
     * @notice Reconstructs a ProveAndClaimCommand struct from public signals and proof bytes.
     * @param pubSignals The array of public signals as output by the ZK circuit.
     * @param proof The zero-knowledge proof bytes.
     * @return command The reconstructed ProveAndClaimCommand struct, ready for encoding or verification.
     */
    function _buildProveAndClaimCommand(
        uint256[] calldata pubSignals,
        bytes memory proof
    )
        internal
        pure
        returns (ProveAndClaimCommand memory command)
    {
        DecodedFields memory decodedFields = _unpackPubSignals(pubSignals);

        return ProveAndClaimCommand({
            domain: decodedFields.domainName,
            email: decodedFields.emailAddress,
            resolver: CircuitUtils.extractCommandParamByIndex(
                _getTemplate(true), decodedFields.maskedCommand, uint256(CommandParamIndex.RESOLVER)
            ),
            emailParts: CircuitUtils.extractEmailParts(decodedFields.emailAddress),
            dkimSignerHash: decodedFields.publicKeyHash,
            owner: Strings.parseAddress(
                CircuitUtils.extractCommandParamByIndex(
                    _getTemplate(true), decodedFields.maskedCommand, uint256(CommandParamIndex.OWNER)
                )
            ),
            nullifier: decodedFields.emailNullifier,
            timestamp: decodedFields.timestamp,
            accountSalt: decodedFields.accountSalt,
            isCodeEmbedded: decodedFields.isCodeExist,
            miscellaneousData: decodedFields.pubKey,
            proof: proof
        });
    }

    /**
     * @notice Packs the decoded fields into the public signals array
     * @param decodedFields The decoded fields struct
     * @return pubSignals The packed public signals array
     */
    function _packPubSignals(DecodedFields memory decodedFields) private pure returns (uint256[60] memory pubSignals) {
        uint256[][] memory fields = new uint256[][](9);
        fields[0] = CircuitUtils.packString(decodedFields.domainName, DOMAIN_NAME_SIZE);
        fields[1] = CircuitUtils.packBytes32(decodedFields.publicKeyHash);
        fields[2] = CircuitUtils.packBytes32(decodedFields.emailNullifier);
        fields[3] = CircuitUtils.packUint256(decodedFields.timestamp);
        fields[4] = CircuitUtils.packString(decodedFields.maskedCommand, MASKED_COMMAND_SIZE);
        fields[5] = CircuitUtils.packBytes32(decodedFields.accountSalt);
        fields[6] = CircuitUtils.packBool(decodedFields.isCodeExist);
        fields[7] = CircuitUtils.packPubKey(decodedFields.pubKey);
        fields[8] = CircuitUtils.packString(decodedFields.emailAddress, EMAIL_ADDRESS_SIZE);
        pubSignals = CircuitUtils.concatFields(fields);

        return pubSignals;
    }

    /**
     * @notice Unpacks the public signals array into a DecodedFields struct
     * @param pubSignals The array of public signals
     * @return decodedFields The decoded fields struct
     */
    function _unpackPubSignals(uint256[] calldata pubSignals)
        private
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
        decodedFields.pubKey = CircuitUtils.unpackPubKey(pubSignals, PUBKEY_OFFSET);
        decodedFields.emailAddress = CircuitUtils.unpackString(pubSignals, EMAIL_ADDRESS_OFFSET, EMAIL_ADDRESS_SIZE);

        return decodedFields;
    }

    /**
     * @notice Returns the command template for the expected command string
     * @param hasResolver Whether the resolver is included in the command
     * @return template The command template as a string array
     */
    function _getTemplate(bool hasResolver) private pure returns (string[] memory template) {
        template = new string[](hasResolver ? 9 : 6);

        template[0] = "Claim";
        template[1] = "ENS";
        template[2] = "name";
        template[3] = "for";
        template[4] = "address";
        template[5] = CommandUtils.ETH_ADDR_MATCHER;
        if (hasResolver) {
            template[6] = "with";
            template[7] = "resolver";
            template[8] = CommandUtils.STRING_MATCHER;
        }

        return template;
    }

    /**
     * @notice Generates the expected command string for a given owner address
     * @param command The ProveAndClaimCommand struct containing the necessary data
     * @return The expected command string that should be present in the verified email
     */
    function _getMaskedCommand(ProveAndClaimCommand memory command) private pure returns (string memory) {
        bool hasResolver = bytes(command.resolver).length != 0;

        bytes[] memory commandParams = new bytes[](hasResolver ? 2 : 1);
        commandParams[0] = abi.encode(command.owner);
        if (hasResolver) {
            commandParams[1] = abi.encode(command.resolver);
        }

        string[] memory template = _getTemplate(hasResolver);

        return CommandUtils.computeExpectedCommand(commandParams, template, 0);
    }
}
