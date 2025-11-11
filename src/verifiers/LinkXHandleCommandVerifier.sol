// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";
import { TextRecord } from "../entrypoints/LinkTextRecordEntrypoint.sol";

import { HandleVerifier } from "./HandleVerifier.sol";
import { PublicInputs } from "./HandleVerifier.sol";

/**
 * @notice Enum representing the indices of command parameters in the command template
 * @dev Used to specify which parameter to extract from the command string
 * @param ENS_NAME = 0
 */
enum CommandParamIndex {
    ENS_NAME
}

struct LinkXHandleCommand {
    TextRecord textRecord;
    bytes proof;
    PublicInputs publicInputs;
}

contract LinkXHandleCommandVerifier is HandleVerifier {
    constructor(address honkVerifier, address dkimRegistry) HandleVerifier(honkVerifier, dkimRegistry) { }

    /**
     * @inheritdoc HandleVerifier
     */
    function verify(bytes memory data) external view override returns (bool) {
        return _isValid(abi.decode(data, (LinkXHandleCommand)));
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
        return abi.encode(_buildLinkXHandleCommand(proof, publicInputs));
    }

    function _isValid(LinkXHandleCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(command.publicInputs.senderDomain, command.publicInputs.pubkeyHash)
        returns (bool)
    {
        PublicInputs memory publicInputs = command.publicInputs;

        return IHonkVerifier(HONK_VERIFIER).verify(command.proof, _packPublicInputs(publicInputs))
            && Strings.equal(command.textRecord.value, publicInputs.xHandle)
            && Strings.equal(_getCommand(command), publicInputs.command);
    }

    function _buildLinkXHandleCommand(
        bytes calldata proof,
        bytes32[] calldata publicInputsFields
    )
        private
        pure
        returns (LinkXHandleCommand memory command)
    {
        PublicInputs memory publicInputs = _unpackPublicInputs(publicInputsFields);
        return LinkXHandleCommand({
            textRecord: TextRecord({
                // ensName is extracted from the command
                ensName: string(
                    CommandUtils.extractCommandParamByIndex(
                        _getTemplate(), publicInputs.command, uint256(CommandParamIndex.ENS_NAME)
                    )
                ),
                // x handle is the value
                value: publicInputs.xHandle,
                nullifier: publicInputs.emailNullifier
            }),
            proof: proof,
            publicInputs: publicInputs
        });
    }

    function _getCommand(LinkXHandleCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(command.textRecord.ensName);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }

    function _getTemplate() private pure returns (string[] memory template) {
        template = new string[](6);

        template[0] = "Link";
        template[1] = "my";
        template[2] = "x";
        template[3] = "handle";
        template[4] = "to";
        template[5] = CommandUtils.STRING_MATCHER;

        return template;
    }
}
