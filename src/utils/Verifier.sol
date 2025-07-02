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
    /**
     * @notice Verifies a Groth16 zero-knowledge proof
     * @param _pA The first component of the proof (A point)
     * @param _pB The second component of the proof (B point)
     * @param _pC The third component of the proof (C point)
     * @param _pubSignals The public signals used in the proof verification
     * @return True if the proof is valid, false otherwise
     * @dev This function verifies a Groth16 zk-SNARK proof by checking that the proof
     *      satisfies the circuit constraints defined by the public signals.
     */
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
     * @notice Error thrown when no valid Ethereum address is found in the command string
     * @dev The command should contain a valid 0x-prefixed Ethereum address
     */
    error NoAddressFoundInCommand();

    /**
     * @notice Error thrown when invalid hexadecimal characters are found in the address parsing
     * @dev Only valid hex characters (0-9, a-f, A-F) are allowed in Ethereum addresses
     */
    error InvalidHexInAddress();

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
     * @dev This function allows off-chain encoding of proof parameters to avoid
     *      expensive on-chain encoding. The backend can call this as a view function
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
                    _unpackFields2Bytes(publicSignals, DOMAIN_NAME_OFFSET, DOMAIN_NAME_FIELDS, DOMAIN_NAME_BYTES)
                ),
                email: string(
                    _unpackFields2Bytes(publicSignals, EMAIL_ADDRESS_OFFSET, EMAIL_ADDRESS_FIELDS, EMAIL_ADDRESS_BYTES)
                ),
                emailParts: _extractEmailParts(
                    _unpackFields2Bytes(publicSignals, EMAIL_ADDRESS_OFFSET, EMAIL_ADDRESS_FIELDS, EMAIL_ADDRESS_BYTES)
                ),
                owner: _extractOwner(
                    // foundry's known line_length soft limit issue: https://github.com/foundry-rs/foundry/issues/4450
                    // solhint-disable-next-line max-line-length
                    _unpackFields2Bytes(publicSignals, MASKED_COMMAND_OFFSET, MASKED_COMMAND_FIELDS, MASKED_COMMAND_BYTES)
                ),
                dkimSignerHash: bytes32(publicSignals[PUBLIC_KEY_HASH_OFFSET]),
                nullifier: bytes32(publicSignals[EMAIL_NULLIFIER_OFFSET]),
                timestamp: publicSignals[TIMESTAMP_OFFSET],
                accountSalt: bytes32(publicSignals[ACCOUNT_SALT_OFFSET]),
                isCodeEmbedded: publicSignals[IS_CODE_EXIST_OFFSET] == 1,
                miscellaneousData: _unpackFields2PubKey(publicSignals, PUBKEY_OFFSET, PUBKEY_FIELDS),
                proof: proof
            })
        );
    }

    /**
     * @notice Unpacks field elements back to bytes
     * @param publicSignals Array of public signals
     * @param startIndex Starting index in publicSignals
     * @param numFields Number of fields to unpack
     * @param paddedSize Original padded size of the bytes
     * @return The unpacked bytes
     */
    function _unpackFields2Bytes(
        uint256[] calldata publicSignals,
        uint256 startIndex,
        uint256 numFields,
        uint256 paddedSize
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(paddedSize);
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < numFields; i++) {
            uint256 field = publicSignals[startIndex + i];
            for (uint256 j = 0; j < 31 && resultIndex < paddedSize; j++) {
                result[resultIndex] = bytes1(uint8(field & 0xFF));
                field = field >> 8;
                resultIndex++;
            }
        }

        // Trim trailing zeros
        uint256 actualLength = 0;
        for (uint256 i = 0; i < result.length; i++) {
            if (result[i] != 0) {
                actualLength = i + 1;
            }
        }

        bytes memory trimmedResult = new bytes(actualLength);
        for (uint256 i = 0; i < actualLength; i++) {
            trimmedResult[i] = result[i];
        }

        return trimmedResult;
    }

    /**
     * @notice Splits email bytes into parts by dots
     * @param emailBytes The email bytes to split
     * @return Array of email parts
     */
    function _extractEmailParts(bytes memory emailBytes) internal pure returns (string[] memory) {
        // replace @ with $
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == "@") {
                emailBytes[i] = "$";
            }
        }

        uint256 dotCount = 0;

        // Count dots
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == ".") {
                dotCount++;
            }
        }

        string[] memory parts = new string[](dotCount + 1);
        uint256 partIndex = 0;
        uint256 startIndex = 0;

        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == ".") {
                parts[partIndex] = _copyBytesToString(emailBytes, startIndex, i);
                partIndex++;
                startIndex = i + 1;
            }
        }

        // Add the last part
        parts[partIndex] = _copyBytesToString(emailBytes, startIndex, emailBytes.length);

        return parts;
    }

    /**
     * @notice Copies a slice of bytes into a new string
     * @param emailBytes The source bytes
     * @param startIndex The starting index (inclusive)
     * @param endIndex The ending index (exclusive)
     * @return The extracted part as a string
     */
    function _copyBytesToString(
        bytes memory emailBytes,
        uint256 startIndex,
        uint256 endIndex
    )
        internal
        pure
        returns (string memory)
    {
        bytes memory part = new bytes(endIndex - startIndex);
        for (uint256 j = startIndex; j < endIndex; j++) {
            part[j - startIndex] = emailBytes[j];
        }
        return string(part);
    }

    /**
     * @notice Extracts the owner address from the command bytes
     * @param commandBytes The command bytes
     * @return The owner address
     */
    function _extractOwner(bytes memory commandBytes) internal pure returns (address) {
        // Convert bytes to string
        string memory commandStr = string(commandBytes);
        bytes memory strBytes = bytes(commandStr);

        // Find the last occurrence of '0x'
        int256 last0x = -1;
        for (uint256 i = 0; i + 1 < strBytes.length; i++) {
            if (strBytes[i] == "0" && (strBytes[i + 1] == "x" || strBytes[i + 1] == "X")) {
                last0x = int256(i);
            }
        }
        if (last0x < 0 || uint256(last0x) + 42 > strBytes.length) revert NoAddressFoundInCommand();

        // Parse the next 40 hex characters
        uint256 addr = 0;
        for (uint256 i = 0; i < 40; i++) {
            uint8 b = uint8(strBytes[uint256(last0x) + 2 + i]);
            uint8 nibble = _hexCharToNibble(b);
            addr = (addr << 4) | uint256(nibble);
        }
        return address(uint160(addr));
    }

    /**
     * @notice Converts a hex character to its numeric value
     * @param b The hex character byte
     * @return The numeric value of the hex character
     */
    function _hexCharToNibble(uint8 b) internal pure returns (uint8) {
        if (b >= 48 && b <= 57) {
            return b - 48; // '0'-'9'
        } else if (b >= 65 && b <= 70) {
            return b - 55; // 'A'-'F'
        } else if (b >= 97 && b <= 102) {
            return b - 87; // 'a'-'f'
        } else {
            revert InvalidHexInAddress();
        }
    }

    /**
     * @notice Unpacks pubkey fields from public signals
     * @param publicSignals Array of public signals
     * @param startIndex Starting index of pubkey fields
     * @param numFields Number of pubkey fields
     * @return ABI-encoded pubkey fields
     */
    function _unpackFields2PubKey(
        uint256[] calldata publicSignals,
        uint256 startIndex,
        uint256 numFields
    )
        internal
        pure
        returns (bytes memory)
    {
        uint256[17] memory pubKeyFields;
        for (uint256 i = 0; i < numFields; i++) {
            pubKeyFields[i] = publicSignals[startIndex + i];
        }
        return abi.encode(pubKeyFields);
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

        // Ensure composedEmail and emailBytes have the same length
        if (composedEmail.length != emailBytes.length) {
            return false;
        }

        // check if the email parts are dot separated and match the claimed email
        // note since @ sign is not in dns encoding valid char set, we are arbitrarily replacing it with a $
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

        uint256[] memory domainFields = _packBytes2Fields(bytes(command.domain), DOMAIN_NAME_BYTES);
        uint256[] memory emailFields = _packBytes2Fields(bytes(command.email), EMAIL_ADDRESS_BYTES);
        uint256[] memory commandFields = _packBytes2Fields(_getExpectedCommand(command.owner), MASKED_COMMAND_BYTES);
        uint256[PUBKEY_FIELDS] memory pubKeyFields = _packPubKey2Fields(command.miscellaneousData);

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

    /**
     * @notice Packs pubkey fields into uint256 array
     * @param fields The pubkey fields to pack
     * @return The packed pubkey fields
     */
    function _packPubKey2Fields(bytes memory fields) internal pure returns (uint256[17] memory) {
        return abi.decode(fields, (uint256[17]));
    }
}
