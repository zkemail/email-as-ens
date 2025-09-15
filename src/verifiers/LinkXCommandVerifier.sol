// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";
import { BoundedVec, Field, FieldArray, NoirUtils } from "../utils/NoirUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";

struct PubSignals {
    Field pubkeyHash;
    Field headerHash0;
    Field headerHash1;
    FieldArray proverAddress;
    FieldArray maskedCommand;
    BoundedVec xHandleCapture1;
}

struct LinkXCommand {
    string xHandle;
    string ensName;
    bytes proof;
    PubSignals pubSignals;
}

contract LinkXCommandVerifier {
    // #1: pubkey_hash 32 bytes -> 1 field -> idx 0
    uint256 public constant PUBKEY_HASH_OFFSET = 0;
    uint256 public constant PUBKEY_HASH_LEN = 1;
    // #2: header_hash_0 32 bytes -> 1 field -> idx 1
    uint256 public constant HEADER_HASH_0_OFFSET = 1;
    uint256 public constant HEADER_HASH_0_LEN = 1;
    // #3: header_hash_1 32 bytes -> 1 field -> idx 2
    uint256 public constant HEADER_HASH_1_OFFSET = 2;
    uint256 public constant HEADER_HASH_1_LEN = 1;
    // #4: prover_address 1 field -> idx 3
    uint256 public constant PROVER_ADDRESS_OFFSET = 3;
    uint256 public constant PROVER_ADDRESS_LEN = 1;
    // #5: masked_command 20 fields -> idx 4-23 (605 bytes)
    uint256 public constant MASKED_COMMAND_OFFSET = 4;
    uint256 public constant MASKED_COMMAND_LEN = 20;
    // #6: x_handle_capture_1 64 fields + 1 field (length) = 65 fields -> idx 24-88
    uint256 public constant X_HANDLE_CAPTURE_1_OFFSET = 24;
    uint256 public constant X_HANDLE_CAPTURE_1_MAX_LEN = 64;

    uint256 public constant PUBLIC_SIGNALS_LENGTH = 89;

    address public immutable HONK_VERIFIER;

    constructor(address _honkVerifier) {
        HONK_VERIFIER = _honkVerifier;
    }

    function verify(bytes memory data) external view returns (bool) {
        return _isValid(abi.decode(data, (LinkXCommand)));
    }

    function encode(
        bytes calldata proof,
        bytes32[] calldata pubSignals
    )
        external
        pure
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildLinkXCommand(pubSignals, proof));
    }

    function _isValid(LinkXCommand memory command) internal view returns (bool) {
        PubSignals memory pubSignals = command.pubSignals;

        return IHonkVerifier(HONK_VERIFIER).verify(command.proof, _encodePubSignals(pubSignals))
            && Strings.equal(command.xHandle, _extractXHandle(pubSignals.xHandleCapture1))
            && Strings.equal(_getMaskedCommand(command), NoirUtils.fieldArrayToString(pubSignals.maskedCommand));
    }

    function _encodePubSignals(PubSignals memory decodedFields) internal pure returns (bytes32[] memory pubSignals) {
        bytes32[][] memory fields = new bytes32[][](6);
        fields[0] = NoirUtils.encodeField(decodedFields.pubkeyHash);
        fields[1] = NoirUtils.encodeField(decodedFields.headerHash0);
        fields[2] = NoirUtils.encodeField(decodedFields.headerHash1);
        fields[3] = NoirUtils.encodeFieldArray(decodedFields.proverAddress);
        fields[4] = NoirUtils.encodeFieldArray(decodedFields.maskedCommand);
        fields[5] = NoirUtils.encodeBoundedVec(decodedFields.xHandleCapture1);

        return NoirUtils.flattenArray(fields, PUBLIC_SIGNALS_LENGTH);
    }

    function _decodePubSignals(bytes32[] calldata encoded) internal pure returns (PubSignals memory decoded) {
        if (encoded.length != PUBLIC_SIGNALS_LENGTH) revert NoirUtils.InvalidPubSignalsLength();

        return PubSignals({
            pubkeyHash: NoirUtils.decodeField(encoded, PUBKEY_HASH_OFFSET),
            headerHash0: NoirUtils.decodeField(encoded, HEADER_HASH_0_OFFSET),
            headerHash1: NoirUtils.decodeField(encoded, HEADER_HASH_1_OFFSET),
            proverAddress: NoirUtils.decodeFieldArray(encoded, PROVER_ADDRESS_OFFSET, PROVER_ADDRESS_LEN),
            maskedCommand: NoirUtils.decodeFieldArray(encoded, MASKED_COMMAND_OFFSET, MASKED_COMMAND_LEN),
            xHandleCapture1: NoirUtils.decodeBoundedVec(encoded, X_HANDLE_CAPTURE_1_OFFSET, X_HANDLE_CAPTURE_1_MAX_LEN)
        });
    }

    function _buildLinkXCommand(
        bytes32[] calldata encodedPubSignals,
        bytes memory proof
    )
        private
        pure
        returns (LinkXCommand memory command)
    {
        PubSignals memory pubSignals = _decodePubSignals(encodedPubSignals);
        return LinkXCommand({
            xHandle: _extractXHandle(pubSignals.xHandleCapture1),
            ensName: string(
                CommandUtils.extractCommandParamByIndex(
                    _getTemplate(), NoirUtils.fieldArrayToString(pubSignals.maskedCommand), 1
                )
            ),
            proof: proof,
            pubSignals: pubSignals
        });
    }

    function _extractXHandle(BoundedVec memory xHandleCapture1) private pure returns (string memory) {
        Field[] memory elements = xHandleCapture1.elements;
        bytes memory out = new bytes(elements.length);
        for (uint256 i = 0; i < elements.length; i++) {
            uint256 fieldValue = uint256(Field.unwrap(elements[i]));
            out[i] = bytes1(uint8(fieldValue & 0xFF));
        }
        return string(out);
    }

    function _getMaskedCommand(LinkXCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](2);
        commandParams[0] = abi.encode(command.xHandle);
        commandParams[1] = abi.encode(command.ensName);

        return CommandUtils.computeExpectedCommand(commandParams, _getTemplate(), 0);
    }

    function _getTemplate() private pure returns (string[] memory template) {
        template = new string[](6);

        template[0] = "Link";
        template[1] = CommandUtils.STRING_MATCHER;
        template[2] = "x";
        template[3] = "handle";
        template[4] = "to";
        template[5] = CommandUtils.STRING_MATCHER;

        return template;
    }
}
