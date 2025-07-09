// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CircuitUtils } from "./CircuitUtils.sol";
import { IGroth16Verifier } from "../interfaces/IGroth16Verifier.sol";

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

    // publicSignals[0-8] -> 9 fields -> domain_name
    uint256 public constant DOMAIN_NAME_OFFSET = 0;
    uint256 public constant DOMAIN_NAME_FIELDS = 9;
    uint256 public constant DOMAIN_NAME_BYTES = 255;
    // publicSignals[9] -> 1 field -> public_key_hash
    uint256 public constant PUBLIC_KEY_HASH_OFFSET = 9;
    // publicSignals[10] -> 1 field -> email_nullifier
    uint256 public constant EMAIL_NULLIFIER_OFFSET = 10;
    // publicSignals[11] -> 1 field -> timestamp
    uint256 public constant TIMESTAMP_OFFSET = 11;
    // publicSignals[12-31] -> 20 fields -> masked_command
    uint256 public constant MASKED_COMMAND_OFFSET = 12;
    uint256 public constant MASKED_COMMAND_FIELDS = 20;
    uint256 public constant MASKED_COMMAND_BYTES = 605;
    // publicSignals[32] -> 1 field -> account_salt
    uint256 public constant ACCOUNT_SALT_OFFSET = 32;
    // publicSignals[33] -> 1 field -> is_code_exist
    uint256 public constant IS_CODE_EXIST_OFFSET = 33;
    // publicSignals[34-50] -> 17 fields -> pubkey
    uint256 public constant PUBKEY_OFFSET = 34;
    uint256 public constant PUBKEY_FIELDS = 17;
    // publicSignals[51-59] -> 9 fields -> email_address
    uint256 public constant EMAIL_ADDRESS_OFFSET = 51;
    uint256 public constant EMAIL_ADDRESS_FIELDS = 9;
    uint256 public constant EMAIL_ADDRESS_BYTES = 256;

    address public immutable GORTH16_VERIFIER;

    /**
     * @notice Error thrown when the public signals array length is not exactly 60
     * @dev The ZK circuit expects exactly 60 public signals for verification
     */
    error InvalidPublicSignalsLength();

    /**
     * @notice Error thrown when the command length is invalid
     * @dev The command should have the expected format and length
     */
    error InvalidCommandLength();

    /**
     * @notice Error thrown when the email doesn't contain an @ symbol
     * @dev Valid email addresses must contain exactly one @ symbol
     */
    error InvalidEmailAddress();

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
     * @notice Unpacks the public signals and proof into a ProveAndClaimCommand struct and encodes it into bytes
     * @param publicSignals Array of public signals from the ZK proof
     * @param proof The zero-knowledge proof bytes
     * @return encodedCommand ABI-encoded ProveAndClaimCommand struct in bytes
     * @dev This function allows off-chain encoding of proof parameters to avoid potentially
     *      expensive on-chain encoding. The backend can call this as a pure function
     *      to get the properly formatted proof data for on-chain submission.
     *
     *      The publicSignals array should contain 60 elements in the same order
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
        uint256[] calldata publicSignals,
        bytes calldata proof
    )
        public
        pure
        returns (bytes memory encodedCommand)
    {
        if (publicSignals.length != 60) revert InvalidPublicSignalsLength();

        return abi.encode(
            ProveAndClaimCommand({
                domain: string(
                    CircuitUtils.unpackFields2Bytes(
                        publicSignals, DOMAIN_NAME_OFFSET, DOMAIN_NAME_FIELDS, DOMAIN_NAME_BYTES
                    )
                ),
                email: string(
                    CircuitUtils.unpackFields2Bytes(
                        publicSignals, EMAIL_ADDRESS_OFFSET, EMAIL_ADDRESS_FIELDS, EMAIL_ADDRESS_BYTES
                    )
                ),
                emailParts: _extractEmailParts(
                    CircuitUtils.unpackFields2Bytes(
                        publicSignals, EMAIL_ADDRESS_OFFSET, EMAIL_ADDRESS_FIELDS, EMAIL_ADDRESS_BYTES
                    )
                ),
                owner: _extractOwner(
                    CircuitUtils.unpackFields2Bytes(
                        publicSignals, MASKED_COMMAND_OFFSET, MASKED_COMMAND_FIELDS, MASKED_COMMAND_BYTES
                    )
                ),
                dkimSignerHash: bytes32(publicSignals[PUBLIC_KEY_HASH_OFFSET]),
                nullifier: bytes32(publicSignals[EMAIL_NULLIFIER_OFFSET]),
                timestamp: publicSignals[TIMESTAMP_OFFSET],
                accountSalt: bytes32(publicSignals[ACCOUNT_SALT_OFFSET]),
                isCodeEmbedded: publicSignals[IS_CODE_EXIST_OFFSET] == 1,
                miscellaneousData: abi.encode(_extractPubKeyFields(publicSignals, PUBKEY_OFFSET, PUBKEY_FIELDS)),
                proof: proof
            })
        );
    }

    /**
     * @notice Builds the public signals required for proof verification
     * @param command The ProveAndClaimCommand struct containing the necessary data
     * @return An array of 60 uint256 values representing the public signals
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
    function _buildPubSignals(ProveAndClaimCommand memory command) internal pure returns (uint256[60] memory) {
        uint256[60] memory pubSignals;

        uint256[] memory domainFields = CircuitUtils.packBytes2Fields(bytes(command.domain), DOMAIN_NAME_BYTES);
        uint256[] memory emailFields = CircuitUtils.packBytes2Fields(bytes(command.email), EMAIL_ADDRESS_BYTES);
        uint256[] memory commandFields =
            CircuitUtils.packBytes2Fields(bytes(_getExpectedCommand(command.owner)), MASKED_COMMAND_BYTES);
        uint256[PUBKEY_FIELDS] memory pubKeyFields = abi.decode(command.miscellaneousData, (uint256[17]));

        // domain_name
        for (uint256 i = 0; i < DOMAIN_NAME_FIELDS; i++) {
            pubSignals[i] = domainFields[i];
        }
        // public_key_hash
        pubSignals[PUBLIC_KEY_HASH_OFFSET] = uint256(command.dkimSignerHash);
        // email_nullifier
        pubSignals[EMAIL_NULLIFIER_OFFSET] = uint256(command.nullifier);
        // timestamp
        pubSignals[TIMESTAMP_OFFSET] = uint256(command.timestamp);
        // masked_command
        for (uint256 i = 0; i < MASKED_COMMAND_FIELDS; i++) {
            pubSignals[MASKED_COMMAND_OFFSET + i] = commandFields[i];
        }
        // account_salt
        pubSignals[ACCOUNT_SALT_OFFSET] = uint256(command.accountSalt);
        // is_code_exist
        pubSignals[IS_CODE_EXIST_OFFSET] = command.isCodeEmbedded ? 1 : 0;
        // pubkey
        for (uint256 i = 0; i < PUBKEY_FIELDS; i++) {
            pubSignals[PUBKEY_OFFSET + i] = pubKeyFields[i];
        }
        // email_address
        for (uint256 i = 0; i < EMAIL_ADDRESS_FIELDS; i++) {
            pubSignals[EMAIL_ADDRESS_OFFSET + i] = emailFields[i];
        }

        return pubSignals;
    }

    /**
     * @notice Verifies that the email parts are dot separated and match the claimed email
     * @param emailParts The parts of the email address dot separated
     * @param email The complete email address
     * @return True if the email parts are dot separated and match the claimed email, false otherwise
     */
    function _verifyEmailParts(string[] memory emailParts, string memory email) internal pure returns (bool) {
        string memory composedEmail = "";
        for (uint256 i = 0; i < emailParts.length; i++) {
            composedEmail = string.concat(composedEmail, emailParts[i]);
            if (i < emailParts.length - 1) {
                composedEmail = string.concat(composedEmail, ".");
            }
        }

        bytes memory emailBytes = bytes(email);
        bytes memory composedEmailBytes = bytes(composedEmail);

        // Ensure composedEmail and emailBytes have the same length
        if (composedEmailBytes.length != emailBytes.length) {
            return false;
        }

        // check if the email parts are dot separated and match the claimed email
        // note since @ sign is not in dns encoding valid char set, we are arbitrarily replacing it with a $
        for (uint256 i = 0; i < emailBytes.length; i++) {
            bytes1 currentByte = emailBytes[i];
            if (currentByte == "@") {
                if (composedEmailBytes[i] != "$") {
                    return false;
                }
            } else if (currentByte != composedEmailBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Generates the expected command string for a given owner address
     * @param _owner The Ethereum address that should appear in the command
     * @return The expected command bytes that should be present in the verified email
     * @dev This function creates the command format: "Claim ENS name for address {ethAddr}"
     *      where {ethAddr} is replaced with the actual Ethereum address.
     */
    function _getExpectedCommand(address _owner) internal pure returns (string memory) {
        string[] memory template = new string[](6);
        template[0] = "Claim";
        template[1] = "ENS";
        template[2] = "name";
        template[3] = "for";
        template[4] = "address";
        template[5] = CommandUtils.ETH_ADDR_MATCHER;
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(_owner);
        return CommandUtils.computeExpectedCommand(commandParams, template, 0);
    }

    function _extractOwner(bytes memory commandBytes) internal pure returns (address) {
        bytes memory prefix = "Claim ENS name for address ";
        // 42 => 0x + 40 hex chars
        if (commandBytes.length != prefix.length + 42) revert InvalidCommandLength();

        bytes memory addressBytes = commandBytes.slice(prefix.length, prefix.length + 42);

        return Strings.parseAddress(string(addressBytes));
    }

    /**
     * @notice Extracts pubkey fields from public signals
     * @param publicSignals Array of public signals
     * @param startIndex Starting index of pubkey fields
     * @param numFields Number of pubkey fields
     * @return Array of pubkey fields
     */
    function _extractPubKeyFields(
        uint256[] calldata publicSignals,
        uint256 startIndex,
        uint256 numFields
    )
        internal
        pure
        returns (uint256[17] memory)
    {
        uint256[17] memory pubKeyFields;
        for (uint256 i = 0; i < numFields; i++) {
            pubKeyFields[i] = publicSignals[startIndex + i];
        }
        return pubKeyFields;
    }

    function _extractEmailParts(bytes memory emailBytes) internal pure returns (string[] memory) {
        bytes memory modifiedEmail = new bytes(emailBytes.length);
        uint256 atIndex = 0;
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == "@") {
                modifiedEmail[i] = "$";
                atIndex = i;
            } else {
                modifiedEmail[i] = emailBytes[i];
            }
        }
        if (atIndex == 0) revert InvalidEmailAddress();
        return _splitString(string(modifiedEmail), ".");
    }

    function _splitString(string memory str, bytes1 delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiter) {
                count++;
            }
        }

        string[] memory parts = new string[](count);
        uint256 lastIndex = 0;
        uint256 partIndex = 0;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiter) {
                bytes memory partBytes = strBytes.slice(lastIndex, i);
                parts[partIndex] = string(partBytes);
                lastIndex = i + 1;
                partIndex++;
            }
        }
        bytes memory lastPartBytes = strBytes.slice(lastIndex, strBytes.length);
        parts[partIndex] = string(lastPartBytes);
        return parts;
    }
}
