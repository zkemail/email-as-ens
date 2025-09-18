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
    bytes32 headerHash;
    string proverAddress;
    string command;
    string xHandleCapture1;
    string senderDomainCapture1;
}

struct LinkXHandleCommand {
    string xHandle;
    string ensName;
    bytes32[] proofFields;
    PubSignals pubSignals;
}

contract LinkXHandleCommandVerifier {
    using Bytes32 for bytes32[];

    // #1: pubkey_hash -> 1 field -> idx 0
    uint256 public constant PUBKEY_HASH_OFFSET = 0;
    // #2: header_hash -> 2 fields -> idx 1-2
    uint256 public constant HEADER_HASH_OFFSET = 1;
    uint256 public constant HEADER_HASH_NUM_FIELDS = 2;
    // #3: prover_address -> 1 field -> idx 3
    uint256 public constant PROVER_ADDRESS_OFFSET = 3;
    uint256 public constant PROVER_ADDRESS_NUM_FIELDS = 1;
    // #4: command 20 fields -> idx 4-23 (605 bytes)
    uint256 public constant COMMAND_OFFSET = 4;
    uint256 public constant COMMAND_NUM_FIELDS = 20;
    // #5: x_handle_capture_1 64 fields + 1 field (length) = 65 fields -> idx 24-88
    uint256 public constant X_HANDLE_CAPTURE_1_OFFSET = 24;
    uint256 public constant X_HANDLE_CAPTURE_1_NUM_FIELDS = 65;
    // #6: sender_domain_capture_1 64 fields + 1 field (length) -> idx 89-153
    uint256 public constant SENDER_DOMAIN_CAPTURE_1_OFFSET = 89;
    uint256 public constant SENDER_DOMAIN_CAPTURE_1_NUM_FIELDS = 65;

    uint256 public constant PUBLIC_SIGNALS_LENGTH = 154;

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
        return _isValid(abi.decode(data, (LinkXHandleCommand)));
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
        return abi.encode(_buildLinkXHandleCommand(pubSignals, proofFields));
    }

    function _isValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) internal view returns (bool) {
        bytes32 domainHash = keccak256(bytes(domainName));
        return IDKIMRegistry(DKIM_REGISTRY).isKeyHashValid(domainHash, dkimKeyHash);
    }

    function _isValid(LinkXHandleCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(command.pubSignals.senderDomainCapture1, command.pubSignals.pubkeyHash)
        returns (bool)
    {
        PubSignals memory pubSignals = command.pubSignals;

        // proof needs to be in non-standard packed mode (abi.encodePacked)
        return IHonkVerifier(HONK_VERIFIER).verify(abi.encodePacked(command.proofFields), _packPubSignals(pubSignals))
            && Strings.equal(command.xHandle, pubSignals.xHandleCapture1)
            && Strings.equal(_getcommand(command), pubSignals.command);
    }

    function _packPubSignals(PubSignals memory decodedFields)
        internal
        pure
        returns (bytes32[] memory publicInputsFields)
    {
        publicInputsFields = new bytes32[](PUBLIC_SIGNALS_LENGTH);
        publicInputsFields[PUBKEY_HASH_OFFSET] = decodedFields.pubkeyHash;
        publicInputsFields.splice(HEADER_HASH_OFFSET, NoirUtils.packHeaderHash(decodedFields.headerHash));
        publicInputsFields.splice(
            PROVER_ADDRESS_OFFSET, NoirUtils.packFieldsArray(decodedFields.proverAddress, PROVER_ADDRESS_NUM_FIELDS)
        );
        publicInputsFields.splice(COMMAND_OFFSET, NoirUtils.packFieldsArray(decodedFields.command, COMMAND_NUM_FIELDS));
        publicInputsFields.splice(
            X_HANDLE_CAPTURE_1_OFFSET,
            NoirUtils.packBoundedVecU8(decodedFields.xHandleCapture1, X_HANDLE_CAPTURE_1_NUM_FIELDS)
        );
        publicInputsFields.splice(
            SENDER_DOMAIN_CAPTURE_1_OFFSET,
            NoirUtils.packBoundedVecU8(decodedFields.senderDomainCapture1, SENDER_DOMAIN_CAPTURE_1_NUM_FIELDS)
        );
    }

    function _unpackPubSignals(bytes32[] calldata encoded) internal pure returns (PubSignals memory decoded) {
        if (encoded.length != PUBLIC_SIGNALS_LENGTH) revert InvalidPubSignalsLength();

        return PubSignals({
            pubkeyHash: encoded[PUBKEY_HASH_OFFSET],
            headerHash: NoirUtils.unpackHeaderHash(
                encoded.slice(HEADER_HASH_OFFSET, HEADER_HASH_OFFSET + HEADER_HASH_NUM_FIELDS)
            ),
            proverAddress: NoirUtils.unpackFieldsArray(
                encoded.slice(PROVER_ADDRESS_OFFSET, PROVER_ADDRESS_OFFSET + PROVER_ADDRESS_NUM_FIELDS)
            ),
            command: NoirUtils.unpackFieldsArray(encoded.slice(COMMAND_OFFSET, COMMAND_OFFSET + COMMAND_NUM_FIELDS)),
            xHandleCapture1: NoirUtils.unpackBoundedVecU8(
                encoded.slice(X_HANDLE_CAPTURE_1_OFFSET, X_HANDLE_CAPTURE_1_OFFSET + X_HANDLE_CAPTURE_1_NUM_FIELDS)
            ),
            senderDomainCapture1: NoirUtils.unpackBoundedVecU8(
                encoded.slice(
                    SENDER_DOMAIN_CAPTURE_1_OFFSET, SENDER_DOMAIN_CAPTURE_1_OFFSET + SENDER_DOMAIN_CAPTURE_1_NUM_FIELDS
                )
            )
        });
    }

    function _buildLinkXHandleCommand(
        bytes32[] calldata encodedPubSignals,
        bytes32[] calldata proofFields
    )
        private
        pure
        returns (LinkXHandleCommand memory command)
    {
        PubSignals memory pubSignals = _unpackPubSignals(encodedPubSignals);
        return LinkXHandleCommand({
            xHandle: pubSignals.xHandleCapture1,
            ensName: string(CommandUtils.extractCommandParamByIndex(_getTemplate(), pubSignals.command, 0)),
            proofFields: proofFields,
            pubSignals: pubSignals
        });
    }

    function _getcommand(LinkXHandleCommand memory command) private pure returns (string memory) {
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(command.ensName);

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
