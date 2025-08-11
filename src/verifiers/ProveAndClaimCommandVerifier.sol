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
        uint256[] calldata pubSignals,
        bytes calldata proof
    )
        external
        pure
        override
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildProveAndClaimCommand(pubSignals, proof));
    }

    function _isValid(ProveAndClaimCommand memory command)
        internal
        view
        onlyValidDKIMHash(command.proof.fields.domainName, command.proof.fields.publicKeyHash)
        returns (bool)
    {
        DecodedFields memory fields = command.proof.fields;
        return _verifyEmailProof(command.proof, GORTH16_VERIFIER)
            && CircuitUtils.verifyEmailParts(command.emailParts, fields.emailAddress)
            && Strings.equal(_getMaskedCommand(command), fields.maskedCommand);
    }

    /**
     * @notice Reconstructs a ProveAndClaimCommand struct from public signals and proof bytes.
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
