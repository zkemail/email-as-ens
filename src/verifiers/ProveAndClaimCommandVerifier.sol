// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CircomUtils } from "@zk-email/contracts/utils/CircomUtils.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { EmailAuthVerifier, EmailAuthProof, PublicInputs } from "./EmailAuthVerifier.sol";
import { EnsUtils } from "../utils/EnsUtils.sol";

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
    EmailAuthProof emailAuthProof;
}

contract ProveAndClaimCommandVerifier is EmailAuthVerifier {
    using Bytes for bytes;
    using Strings for string;
    using CircomUtils for bytes;
    using CommandUtils for bytes;

    constructor(address _groth16Verifier, address _dkimRegistry) EmailAuthVerifier(_groth16Verifier, _dkimRegistry) { }

    /**
     * @inheritdoc EmailAuthVerifier
     */
    function verify(bytes memory data) external view override returns (bool) {
        return _isValid(abi.decode(data, (ProveAndClaimCommand)));
    }

    /**
     * @inheritdoc EmailAuthVerifier
     */
    function encode(
        bytes calldata proof,
        bytes32[] calldata publicInputs
    )
        external
        pure
        override
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildProveAndClaimCommand(proof, publicInputs));
    }

    function _isValid(ProveAndClaimCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(
            command.emailAuthProof.publicInputs.domainName,
            command.emailAuthProof.publicInputs.publicKeyHash
        )
        returns (bool)
    {
        PublicInputs memory fields = command.emailAuthProof.publicInputs;
        return _verifyEmailProof(GORTH16_VERIFIER, command.emailAuthProof)
            && EnsUtils.verifyEmailParts(command.emailParts, fields.emailAddress)
            && Strings.equal(_getMaskedCommand(command), fields.maskedCommand);
    }

    /**
     * @notice Reconstructs a ProveAndClaimCommand struct from public signals and proof bytes.
     */
    function _buildProveAndClaimCommand(
        bytes memory proof,
        bytes32[] calldata publicInputsFields
    )
        private
        pure
        returns (ProveAndClaimCommand memory command)
    {
        PublicInputs memory publicInputs = _unpackPublicInputs(publicInputsFields);

        return ProveAndClaimCommand({
            resolver: CommandUtils.extractCommandParamByIndex(
                _getTemplate(), publicInputs.maskedCommand, uint256(CommandParamIndex.RESOLVER)
            ),
            emailParts: EnsUtils.extractEmailParts(publicInputs.emailAddress),
            owner: Strings.parseAddress(
                CommandUtils.extractCommandParamByIndex(
                    _getTemplate(), publicInputs.maskedCommand, uint256(CommandParamIndex.OWNER)
                )
            ),
            emailAuthProof: EmailAuthProof({ publicInputs: publicInputs, proof: proof })
        });
    }

    function _getMaskedCommand(ProveAndClaimCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](2);
        commandParams[0] = abi.encode(command.owner);
        commandParams[1] = abi.encode(command.resolver);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }

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
}
