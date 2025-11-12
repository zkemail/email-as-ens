// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";
import { HandleVerifier } from "./HandleVerifier.sol";
import { PublicInputs } from "./HandleVerifier.sol";

/**
 * @notice Enum representing the indices of command parameters in the command template
 * @dev Used to specify which parameter to extract from the command string
 * @param TARGET = 0
 */
enum CommandParamIndex {
    TARGET
}

struct ClaimXHandleCommand {
    address target;
    bytes proof;
    PublicInputs publicInputs;
}

contract ClaimXHandleCommandVerifier is HandleVerifier {
    constructor(address honkVerifier, address dkimRegistry) HandleVerifier(honkVerifier, dkimRegistry) { }

    /**
     * @inheritdoc HandleVerifier
     */
    function verify(bytes memory data) external view override returns (bool) {
        return _isValid(abi.decode(data, (ClaimXHandleCommand)));
    }

    /**
     * @inheritdoc HandleVerifier
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
        return abi.encode(_buildClaimXHandleCommand(proof, publicInputs));
    }

    function _isValid(ClaimXHandleCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(command.publicInputs.senderDomain, command.publicInputs.pubkeyHash)
        returns (bool)
    {
        PublicInputs memory publicInputs = command.publicInputs;

        return IHonkVerifier(HONK_VERIFIER).verify(command.proof, _packPublicInputs(publicInputs))
            && Strings.equal(_getCommand(command), publicInputs.command);
    }

    function _buildClaimXHandleCommand(
        bytes calldata proof,
        bytes32[] calldata publicInputsFields
    )
        private
        pure
        returns (ClaimXHandleCommand memory command)
    {
        PublicInputs memory publicInputs = _unpackPublicInputs(publicInputsFields);
        return ClaimXHandleCommand({
            target: Strings.parseAddress(
                CommandUtils.extractCommandParamByIndex(
                    _getTemplate(), publicInputs.command, uint256(CommandParamIndex.TARGET)
                )
            ),
            proof: proof,
            publicInputs: publicInputs
        });
    }

    function _getCommand(ClaimXHandleCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(command.target);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }

    function _getTemplate() private pure returns (string[] memory template) {
        template = new string[](5);

        template[0] = "Withdraw";
        template[1] = "all";
        template[2] = "eth";
        template[3] = "to";
        template[4] = CommandUtils.ETH_ADDR_MATCHER;

        return template;
    }
}
