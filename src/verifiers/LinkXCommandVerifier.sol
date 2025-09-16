// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { NoirUtils } from "../utils/NoirUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes32 } from "../utils/Bytes32.sol";

struct PubSignals {
    bytes32 pubkeyHash;
    bytes32 headerHash0;
    bytes32 headerHash1;
    string proverAddress;
    string maskedCommand;
    string xHandleCapture1;
}

struct LinkXCommand {
    string xHandle;
    string ensName;
    bytes32[] proofFields;
    PubSignals pubSignals;
}

contract LinkXCommandVerifier {
    using Bytes32 for bytes32[];

    // #1: pubkey_hash -> 1 field -> idx 0
    uint256 public constant PUBKEY_HASH_OFFSET = 0;
    // #2: header_hash_0 -> 1 field -> idx 1
    uint256 public constant HEADER_HASH_0_OFFSET = 1;
    // #3: header_hash_1 -> 1 field -> idx 2
    uint256 public constant HEADER_HASH_1_OFFSET = 2;
    // #4: prover_address -> 1 field -> idx 3
    uint256 public constant PROVER_ADDRESS_OFFSET = 3;
    uint256 public constant PROVER_ADDRESS_NUM_FIELDS = 1;
    // #5: masked_command 20 fields -> idx 4-23 (605 bytes)
    uint256 public constant MASKED_COMMAND_OFFSET = 4;
    uint256 public constant MASKED_COMMAND_NUM_FIELDS = 20;
    // #6: x_handle_capture_1 64 fields + 1 field (length) = 65 fields -> idx 24-88
    uint256 public constant X_HANDLE_CAPTURE_1_OFFSET = 24;
    uint256 public constant X_HANDLE_CAPTURE_1_NUM_FIELDS = 65;

    uint256 public constant PUBLIC_SIGNALS_LENGTH = 89;

    address public immutable HONK_VERIFIER;
    address public immutable DKIM_REGISTRY;

    error InvalidPubSignalsLength();

    error InvalidDkimKeyHash();

    modifier onlyValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) {
        if (!_isValidDkimKeyHash(domainName, dkimKeyHash)) revert InvalidDkimKeyHash();
        _;
    }

    constructor(address _honkVerifier, address _dkimRegistry) {
        HONK_VERIFIER = _honkVerifier;
        DKIM_REGISTRY = _dkimRegistry;
    }

    function verify(bytes memory data) external view returns (bool) {
        return _isValid(abi.decode(data, (LinkXCommand)));
    }

    function dkimRegistryAddress() external view returns (address) {
        return DKIM_REGISTRY;
    }

    function encode(
        bytes32[] calldata proofFields,
        bytes32[] calldata pubSignals
    )
        external
        pure
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildLinkXCommand(pubSignals, proofFields));
    }

    function _isValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) internal view returns (bool) {
        bytes32 domainHash = keccak256(bytes(domainName));
        return IDKIMRegistry(DKIM_REGISTRY).isKeyHashValid(domainHash, dkimKeyHash);
    }

    function _isValid(LinkXCommand memory command)
        internal
        view
        onlyValidDkimKeyHash("domainName", command.pubSignals.pubkeyHash)
        returns (bool)
    {
        PubSignals memory pubSignals = command.pubSignals;

        // proof needs to be in non-standard packed mode (abi.encodePacked)
        return IHonkVerifier(HONK_VERIFIER).verify(abi.encodePacked(command.proofFields), _packPubSignals(pubSignals))
            && Strings.equal(command.xHandle, pubSignals.xHandleCapture1)
            && Strings.equal(_getMaskedCommand(command), pubSignals.maskedCommand);
    }

    function _packPubSignals(PubSignals memory decodedFields)
        internal
        pure
        returns (bytes32[] memory publicInputsFields)
    {
        publicInputsFields = new bytes32[](PUBLIC_SIGNALS_LENGTH);
        publicInputsFields[PUBKEY_HASH_OFFSET] = decodedFields.pubkeyHash;
        publicInputsFields[HEADER_HASH_0_OFFSET] = decodedFields.headerHash0;
        publicInputsFields[HEADER_HASH_1_OFFSET] = decodedFields.headerHash1;
        publicInputsFields.splice(
            PROVER_ADDRESS_OFFSET, NoirUtils.packFieldsArray(decodedFields.proverAddress, PROVER_ADDRESS_NUM_FIELDS)
        );
        publicInputsFields.splice(
            MASKED_COMMAND_OFFSET, NoirUtils.packFieldsArray(decodedFields.maskedCommand, MASKED_COMMAND_NUM_FIELDS)
        );
        publicInputsFields.splice(
            X_HANDLE_CAPTURE_1_OFFSET,
            NoirUtils.packBoundedVecU8(decodedFields.xHandleCapture1, X_HANDLE_CAPTURE_1_NUM_FIELDS)
        );
    }

    function _unpackPubSignals(bytes32[] calldata encoded) internal pure returns (PubSignals memory decoded) {
        if (encoded.length != PUBLIC_SIGNALS_LENGTH) revert InvalidPubSignalsLength();

        return PubSignals({
            pubkeyHash: encoded[PUBKEY_HASH_OFFSET],
            headerHash0: encoded[HEADER_HASH_0_OFFSET],
            headerHash1: encoded[HEADER_HASH_1_OFFSET],
            proverAddress: NoirUtils.unpackFieldsArray(
                encoded.slice(PROVER_ADDRESS_OFFSET, PROVER_ADDRESS_OFFSET + PROVER_ADDRESS_NUM_FIELDS)
            ),
            maskedCommand: NoirUtils.unpackFieldsArray(
                encoded.slice(MASKED_COMMAND_OFFSET, MASKED_COMMAND_OFFSET + MASKED_COMMAND_NUM_FIELDS)
            ),
            xHandleCapture1: NoirUtils.unpackBoundedVecU8(
                encoded.slice(X_HANDLE_CAPTURE_1_OFFSET, X_HANDLE_CAPTURE_1_OFFSET + X_HANDLE_CAPTURE_1_NUM_FIELDS)
            )
        });
    }

    function _buildLinkXCommand(
        bytes32[] calldata encodedPubSignals,
        bytes32[] calldata proofFields
    )
        private
        pure
        returns (LinkXCommand memory command)
    {
        PubSignals memory pubSignals = _unpackPubSignals(encodedPubSignals);
        return LinkXCommand({
            xHandle: pubSignals.xHandleCapture1,
            ensName: string(CommandUtils.extractCommandParamByIndex(_getTemplate(), pubSignals.maskedCommand, 1)),
            proofFields: proofFields,
            pubSignals: pubSignals
        });
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
