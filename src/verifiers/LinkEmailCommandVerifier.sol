// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CircuitUtils } from "../utils/CircuitUtils.sol";
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

    address public immutable GORTH16_VERIFIER;

    constructor(address _groth16Verifier) {
        GORTH16_VERIFIER = _groth16Verifier;
    }

    function isValid(bytes memory data) external view returns (bool) {
        LinkEmailCommand memory command = abi.decode(data, (LinkEmailCommand));
        DecodedFields memory fields = command.proof.fields;
        return _isValidEmailProof(command.proof, GORTH16_VERIFIER)
            && Strings.equal(command.email, command.proof.fields.emailAddress)
            && Strings.equal(_getMaskedCommand(command), fields.maskedCommand);
    }

    function encode(
        uint256[] calldata pubSignals,
        bytes calldata proof
    )
        public
        pure
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildLinkEmailCommand(pubSignals, proof));
    }

    function _buildLinkEmailCommand(
        uint256[] calldata pubSignals,
        bytes memory proof
    )
        internal
        pure
        returns (LinkEmailCommand memory command)
    {
        DecodedFields memory decodedFields = _unpackPubSignals(pubSignals);

        return LinkEmailCommand({
            email: decodedFields.emailAddress,
            ensName: string(CircuitUtils.extractCommandParamByIndex(_getTemplate(), decodedFields.maskedCommand, 0)),
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
