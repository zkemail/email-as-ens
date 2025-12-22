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
 * @param RECIPIENT = 0
 */
enum CommandParamIndex {
    RECIPIENT
}

struct ClaimHandleCommand {
    address target;
    bytes proof;
    PublicInputs publicInputs;
}

contract ClaimHandleCommandVerifier is HandleVerifier {
    constructor(address honkVerifier, address dkimRegistry) HandleVerifier(honkVerifier, dkimRegistry) { }

    /**
     * @inheritdoc HandleVerifier
     */
    function verify(bytes memory data) external view override returns (bool) {
        return _isValid(abi.decode(data, (ClaimHandleCommand)));
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
        return abi.encode(_buildClaimHandleCommand(proof, publicInputs));
    }

    function _isValid(ClaimHandleCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(command.publicInputs.senderDomain, command.publicInputs.pubkeyHash)
        returns (bool)
    {
        PublicInputs memory publicInputs = command.publicInputs;

        return IHonkVerifier(HONK_VERIFIER).verify(command.proof, _packPublicInputs(publicInputs))
            && _checkCommand(command, publicInputs.command);
    }

    function _buildClaimHandleCommand(
        bytes calldata proof,
        bytes32[] calldata publicInputsFields
    )
        private
        pure
        returns (ClaimHandleCommand memory command)
    {
        PublicInputs memory publicInputs = _unpackPublicInputs(publicInputsFields);
        return ClaimHandleCommand({
            target: Strings.parseAddress(
                CommandUtils.extractCommandParamByIndex(
                    _getTemplate(), publicInputs.command, uint256(CommandParamIndex.RECIPIENT)
                )
            ),
            proof: proof,
            publicInputs: publicInputs
        });
    }

    function _checkCommand(
        ClaimHandleCommand memory command,
        string memory expectedCommand
    )
        private
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < 2; i++) {
            if (Strings.equal(_getCommand(command, i), expectedCommand)) {
                return true;
            }
        }
        return false;
    }

    function _getCommand(ClaimHandleCommand memory command, uint256 casing) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(command.target);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), casing);
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
