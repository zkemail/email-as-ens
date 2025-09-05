// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CircuitUtils } from "@zk-email/contracts/CircuitUtils.sol";
import { EmailAuthVerifier, DecodedFields, EmailAuthProof } from "./EmailAuthVerifier.sol";

struct LinkEmailCommand {
    string email;
    string ensName;
    EmailAuthProof proof;
}

contract LinkEmailCommandVerifier is EmailAuthVerifier {
    using Bytes for bytes;
    using Strings for string;
    using CircuitUtils for bytes;

    constructor(address _groth16Verifier, address _dkimRegistry) EmailAuthVerifier(_groth16Verifier, _dkimRegistry) { }

    /**
     * @inheritdoc EmailAuthVerifier
     */
    function verify(bytes memory data) external view override returns (bool) {
        return _isValid(abi.decode(data, (LinkEmailCommand)));
    }

    /**
     * @inheritdoc EmailAuthVerifier
     */
    function encode(
        uint256[] calldata pubSignals,
        bytes calldata proof
    )
        external
        pure
        override
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildLinkEmailCommand(pubSignals, proof));
    }

    function _isValid(LinkEmailCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(command.proof.fields.domainName, command.proof.fields.publicKeyHash)
        returns (bool)
    {
        DecodedFields memory fields = command.proof.fields;
        return _verifyEmailProof(command.proof, GORTH16_VERIFIER)
            && Strings.equal(command.email, command.proof.fields.emailAddress)
            && Strings.equal(_getMaskedCommand(command), fields.maskedCommand);
    }

    /**
     * @notice Reconstructs a LinkEmailCommand struct from public signals and proof bytes.
     */
    function _buildLinkEmailCommand(
        uint256[] calldata pubSignals,
        bytes memory proof
    )
        private
        pure
        returns (LinkEmailCommand memory command)
    {
        DecodedFields memory decodedFields = _unpackPubSignals(pubSignals);

        return LinkEmailCommand({
            email: decodedFields.emailAddress,
            ensName: string(CommandUtils.extractCommandParamByIndex(_getTemplate(), decodedFields.maskedCommand, 0)),
            proof: EmailAuthProof({ fields: decodedFields, proof: proof })
        });
    }

    function _getMaskedCommand(LinkEmailCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(command.ensName);
        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }

    function _getTemplate() private pure returns (string[] memory template) {
        template = new string[](5);

        template[0] = "Link";
        template[1] = "my";
        template[2] = "email";
        template[3] = "to";
        template[4] = CommandUtils.STRING_MATCHER;

        return template;
    }
}
