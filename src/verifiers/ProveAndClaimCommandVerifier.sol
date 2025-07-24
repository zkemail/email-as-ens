// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CircuitUtils } from "../utils/CircuitUtils.sol";
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
     */
    function verify(bytes memory data) external view returns (bool) {
        ProveAndClaimCommand memory command = abi.decode(data, (ProveAndClaimCommand));
        DecodedFields memory fields = command.proof.fields;
        return _verifyEmailProof(command.proof, GORTH16_VERIFIER)
            && CircuitUtils.verifyEmailParts(command.emailParts, fields.emailAddress)
            && Strings.equal(_getMaskedCommand(command), fields.maskedCommand);
    }

    /**
     * @notice Unpacks the public signals and proof into a ProveAndClaimCommand struct and encodes it into bytes
     * @param pubSignals Array of public signals from the ZK proof, usually provided by the relayer
     * @param proof The zero-knowledge proof bytes
     * @return encodedCommand ABI-encoded ProveAndClaimCommand struct in bytes
     */
    function encode(
        uint256[] calldata pubSignals,
        bytes calldata proof
    )
        external
        pure
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildProveAndClaimCommand(pubSignals, proof));
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
        private
        pure
        returns (ProveAndClaimCommand memory command)
    {
        DecodedFields memory decodedFields = _unpackPubSignals(pubSignals);

        return ProveAndClaimCommand({
            resolver: CircuitUtils.extractCommandParamByIndex(
                _getTemplate(), decodedFields.maskedCommand, uint256(CommandParamIndex.RESOLVER)
            ),
            emailParts: CircuitUtils.extractEmailParts(decodedFields.emailAddress),
            owner: Strings.parseAddress(
                CircuitUtils.extractCommandParamByIndex(
                    _getTemplate(), decodedFields.maskedCommand, uint256(CommandParamIndex.OWNER)
                )
            ),
            proof: EmailAuthProof({ fields: decodedFields, proof: proof })
        });
    }

    /**
     * @notice Returns the command template for the expected command string
     * @return template The command template as a string array
     */
    function _getTemplate() private pure returns (string[] memory template) {
        template = new string[](9);

        template[0] = "Claim";
        template[1] = "ENS";
        template[2] = "name";
        template[3] = "for";
        template[4] = "address";
        template[5] = CommandUtils.ETH_ADDR_MATCHER;
        template[6] = "with";
        template[7] = "resolver";
        template[8] = CommandUtils.STRING_MATCHER;

        return template;
    }

    /**
     * @notice Generates the expected command string for a given owner address
     * @param command The ProveAndClaimCommand struct containing the necessary data
     * @return The expected command string that should be present in the verified email
     */
    function _getMaskedCommand(ProveAndClaimCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](2);
        commandParams[0] = abi.encode(command.owner);
        commandParams[1] = abi.encode(command.resolver);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }
}
