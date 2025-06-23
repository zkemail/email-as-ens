// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";

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

interface IGroth16Verifier {
    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[60] calldata _pubSignals
    )
        external
        view
        returns (bool);
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

    /// @notice The order of the BN128 elliptic curve used in the ZK proofs
    /// @dev All field elements in proofs must be less than this value
    uint256 public constant Q =
        21_888_242_871_839_275_222_246_405_745_257_275_088_696_311_157_297_823_662_689_037_894_645_226_208_583;

    uint256 public constant DOMAIN_FIELDS = 9;
    uint256 public constant DOMAIN_BYTES = 255;
    uint256 public constant EMAIL_FIELDS = 9;
    uint256 public constant EMAIL_BYTES = 256;
    uint256 public constant COMMAND_FIELDS = 20;
    uint256 public constant COMMAND_BYTES = 605;
    uint256 public constant PUBKEY_FIELDS = 17;
    address public immutable GORTH16_VERIFIER;

    /**
     * @notice Initializes the verifier with a Groth16 verifier contract
     * @param _groth16Verifier The address of the deployed Groth16Verifier contract
     * @dev The Groth16 verifier must be compatible with the specific circuit used for email verification.
     *      This address is immutable to prevent unauthorized changes to the verification logic.
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
     *
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

        if (!_verifyEmailParts(command.emailParts, command.email)) {
            return false;
        }

        // build the public signals
        uint256[60] memory pubSignals = _buildPubSignals(command);

        // verify the proof
        return IGroth16Verifier(GORTH16_VERIFIER).verifyProof(pA, pB, pC, pubSignals);

        // todo: verify DKIM oracle proof
    }

    /**
     * @notice Verifies that the email parts are dot separated and match the claimed email
     * @param emailParts The parts of the email address dot separated
     * @param email The complete email address
     * @return True if the email parts are dot separated and match the claimed email, false otherwise
     */
    function _verifyEmailParts(string[] memory emailParts, string memory email) internal pure returns (bool) {
        bytes memory composedEmail = bytes("");
        for (uint256 i = 0; i < emailParts.length; i++) {
            composedEmail = abi.encodePacked(composedEmail, bytes(emailParts[i]));
            if (i < emailParts.length - 1) {
                composedEmail = abi.encodePacked(composedEmail, bytes("."));
            }
        }

        bytes memory emailBytes = bytes(email);

        // check if the email parts are dot separated and match the claimed email
        // note since at sign is not in dns encoding valid char set, we are arbitrarily replacing it with a $
        // note to reviewer: this is a bit of a hack, what better way to do this?
        for (uint256 i = 0; i < emailBytes.length; i++) {
            bytes1 currentByte = emailBytes[i];
            if (currentByte == "@") {
                if (composedEmail[i] != "$") {
                    return false;
                }
            } else if (currentByte != composedEmail[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Builds the public signals required for proof verification
     * @param command The ProveAndClaimCommand struct containing the necessary data
     * @return An array of 60 uint256 values representing the public signals
     * @dev The public signals are structured as follows (in order, totaling 60 fields):
     *      - domain_name: 9 fields (packed representation of the email domain)
     *      - public_key_hash: 1 field (hash of the DKIM RSA public key)
     *      - email_nullifier: 1 field (unique identifier preventing replay attacks)
     *      - timestamp: 1 field (email timestamp, 0 if not supported)
     *      - masked_command: 20 fields (packed representation of the expected command)
     *      - account_salt: 1 field (additional randomness for security)
     *      - is_code_exist: 1 field (boolean indicating embedded verification code)
     *      - pubkey: 17 fields (decomposed RSA public key components)
     *      - email_address: 9 fields (packed representation of the full email address)
     *
     *      All string data (domain, email, command) is packed into field elements using a specific
     *      encoding scheme that packs 31 bytes per field element for efficiency.
     *
     *      The expected command format is: "Claim ENS name for address {ethAddr}"
     *      where {ethAddr} is replaced with the actual Ethereum address from the command.
     */
    function _buildPubSignals(ProveAndClaimCommand memory command) internal pure returns (uint256[60] memory) {
        uint256[60] memory pubSignals;

        uint256[] memory domainFields = _packBytes2Fields(bytes(command.domain), DOMAIN_BYTES);
        uint256[] memory emailFields = _packBytes2Fields(bytes(command.email), EMAIL_BYTES);
        uint256[] memory commandFields = _packBytes2Fields(_getExpectedCommand(command.owner), COMMAND_BYTES);
        uint256[PUBKEY_FIELDS] memory pubKeyFields = abi.decode(command.miscellaneousData, (uint256[17]));

        // domain_name
        for (uint256 i = 0; i < DOMAIN_FIELDS; i++) {
            pubSignals[i] = domainFields[i];
        }
        // public_key_hash
        pubSignals[DOMAIN_FIELDS] = uint256(command.dkimSignerHash);
        // email_nullifier
        pubSignals[DOMAIN_FIELDS + 1] = uint256(command.nullifier);
        // timestamp
        pubSignals[DOMAIN_FIELDS + 2] = uint256(command.timestamp);
        // masked_command
        for (uint256 i = 0; i < COMMAND_FIELDS; i++) {
            pubSignals[DOMAIN_FIELDS + 3 + i] = commandFields[i];
        }
        // account_salt
        pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS] = uint256(command.accountSalt);
        // is_code_exist
        pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS + 1] = command.isCodeEmbedded ? 1 : 0;
        // pubkey
        for (uint256 i = 0; i < PUBKEY_FIELDS; i++) {
            pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS + 2 + i] = pubKeyFields[i];
        }
        // email_address
        for (uint256 i = 0; i < EMAIL_FIELDS; i++) {
            pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS + 2 + PUBKEY_FIELDS + i] = emailFields[i];
        }

        return pubSignals;
    }

    /**
     * @notice Packs byte arrays into field elements for ZK circuit compatibility
     * @param _bytes The byte array to pack into field elements
     * @param _paddedSize The target size after padding (must be larger than or equal to _bytes.length)
     * @return An array of field elements containing the packed byte data
     * @dev This function packs bytes into field elements by:
     *      1. Determining how many field elements are needed (31 bytes per field element)
     *      2. Packing bytes in little-endian order within each field element
     *      3. Padding with zeros if the input is shorter than _paddedSize
     *      4. Ensuring the resulting field elements are compatible with ZK circuits
     *
     *      Each field element can contain up to 31 bytes to ensure the result stays below
     *      the BN128 curve order. Bytes are packed as: byte0 + (byte1 << 8) + (byte2 << 16) + ...
     */
    function _packBytes2Fields(bytes memory _bytes, uint256 _paddedSize) internal pure returns (uint256[] memory) {
        uint256 remain = _paddedSize % 31;
        uint256 numFields = (_paddedSize - remain) / 31;
        if (remain > 0) {
            numFields += 1;
        }
        uint256[] memory fields = new uint256[](numFields);
        uint256 idx = 0;
        uint256 byteVal = 0;
        for (uint256 i = 0; i < numFields; i++) {
            for (uint256 j = 0; j < 31; j++) {
                idx = i * 31 + j;
                if (idx >= _paddedSize) {
                    break;
                }
                if (idx >= _bytes.length) {
                    byteVal = 0;
                } else {
                    byteVal = uint256(uint8(_bytes[idx]));
                }
                if (j == 0) {
                    fields[i] = byteVal;
                } else {
                    fields[i] += (byteVal << (8 * j));
                }
            }
        }
        return fields;
    }

    /**
     * @notice Generates the expected command string for a given owner address
     * @param _owner The Ethereum address that should appear in the command
     * @return The expected command bytes that should be present in the verified email
     * @dev This function creates the command format: "Claim ENS name for address {ethAddr}"
     *      where {ethAddr} is replaced with the actual Ethereum address.
     */
    function _getExpectedCommand(address _owner) internal pure returns (bytes memory) {
        string[] memory template = new string[](6);
        template[0] = "Claim";
        template[1] = "ENS";
        template[2] = "name";
        template[3] = "for";
        template[4] = "address";
        template[5] = CommandUtils.ETH_ADDR_MATCHER;
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(_owner);
        return bytes(CommandUtils.computeExpectedCommand(commandParams, template, 0));
    }
}
