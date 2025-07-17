// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CircuitUtils } from "./CircuitUtils.sol";
import { IGroth16Verifier } from "../interfaces/IGroth16Verifier.sol";
import { EmailAuthVerifier, DecodedFields, EmailAuthProof } from "./EmailAuthVerifier.sol";

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

struct ProveAndClaimCommand {
    string resolver;
    string[] emailParts;
    address owner;
    EmailAuthProof proof;
}

contract ProveAndClaimCommandVerifier is EmailAuthVerifier {
    using Bytes for bytes;
    using Strings for string;
    using CircuitUtils for bytes;

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
        ProveAndClaimCommand memory command = abi.decode(data, (ProveAndClaimCommand));

        if (!_isValidEmailProof(command.proof, GORTH16_VERIFIER)) {
            return false;
        }

        if (!CircuitUtils.verifyEmailParts(command.emailParts, command.proof.fields.emailAddress)) {
            return false;
        }

        string memory expectedCommand = _getMaskedCommand(command);
        if (!Strings.equal(expectedCommand, command.proof.fields.maskedCommand)) {
            return false;
        }

        return true;
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
        pubSignals = _packPubSignals(command.proof.fields);
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
            resolver: CircuitUtils.extractCommandParamByIndex(
                _getTemplate(true), decodedFields.maskedCommand, uint256(CommandParamIndex.RESOLVER)
            ),
            emailParts: CircuitUtils.extractEmailParts(decodedFields.emailAddress),
            owner: Strings.parseAddress(
                CircuitUtils.extractCommandParamByIndex(
                    _getTemplate(true), decodedFields.maskedCommand, uint256(CommandParamIndex.OWNER)
                )
            ),
            proof: EmailAuthProof({ fields: decodedFields, proof: proof })
        });
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
