// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { NoirUtils } from "../utils/NoirUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";
import { Bytes32 } from "../utils/Bytes32.sol";
import { TextRecord } from "../LinkTextRecordVerifier.sol";
import { IVerifier } from "../interfaces/IVerifier.sol";

/**
 * @notice Enum representing the indices of command parameters in the command template
 * @dev Used to specify which parameter to extract from the command string
 * @param ENS_NAME = 0
 */
enum CommandParamIndex {
    ENS_NAME
}

struct PublicInputs {
    bytes32 pubkeyHash;
    bytes32 headerHash;
    string proverAddress;
    string command;
    string xHandleCapture1;
    string senderDomainCapture1;
}

struct LinkXHandleCommand {
    TextRecord textRecord;
    bytes proof;
    PublicInputs publicInputs;
}

contract LinkXHandleCommandVerifier is IVerifier {
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

    uint256 public constant PUBLIC_INPUTS_LENGTH = 154;

    address public immutable HONK_VERIFIER;
    address public immutable DKIM_REGISTRY;

    error InvalidPublicInputsLength();

    error InvalidDkimKeyHash();

    modifier onlyValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) {
        if (!_isValidDkimKeyHash(domainName, dkimKeyHash)) revert InvalidDkimKeyHash();
        _;
    }

    constructor(address _honkVerifier, address _dkimRegistry) {
        HONK_VERIFIER = _honkVerifier;
        DKIM_REGISTRY = _dkimRegistry;
    }

    function dkimRegistryAddress() external view returns (address) {
        return DKIM_REGISTRY;
    }

    function encode(
        bytes calldata proof,
        bytes32[] calldata publicInputs
    )
        external
        view
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildLinkXHandleCommand(proof, publicInputs));
    }

    function verify(bytes memory data) external view returns (bool) {
        return _isValid(abi.decode(data, (LinkXHandleCommand)));
    }

    function _isValidDkimKeyHash(string memory domainName, bytes32 dkimKeyHash) internal view returns (bool) {
        bytes32 domainHash = keccak256(bytes(domainName));
        return IDKIMRegistry(DKIM_REGISTRY).isKeyHashValid(domainHash, dkimKeyHash);
    }

    function _isValid(LinkXHandleCommand memory command)
        internal
        view
        onlyValidDkimKeyHash(command.publicInputs.senderDomainCapture1, command.publicInputs.pubkeyHash)
        returns (bool)
    {
        PublicInputs memory publicInputs = command.publicInputs;

        return IHonkVerifier(HONK_VERIFIER).verify(command.proof, _packPublicInputs(publicInputs))
            && Strings.equal(command.textRecord.value, publicInputs.xHandleCapture1)
            && Strings.equal(_getCommand(command), publicInputs.command);
    }

    function _packPublicInputs(PublicInputs memory publicInputs) internal pure returns (bytes32[] memory fields) {
        fields = new bytes32[](PUBLIC_INPUTS_LENGTH);
        fields[PUBKEY_HASH_OFFSET] = publicInputs.pubkeyHash;
        fields.splice(HEADER_HASH_OFFSET, NoirUtils.packHeaderHash(publicInputs.headerHash));
        fields.splice(
            PROVER_ADDRESS_OFFSET, NoirUtils.packFieldsArray(publicInputs.proverAddress, PROVER_ADDRESS_NUM_FIELDS)
        );
        fields.splice(COMMAND_OFFSET, NoirUtils.packFieldsArray(publicInputs.command, COMMAND_NUM_FIELDS));
        fields.splice(
            X_HANDLE_CAPTURE_1_OFFSET,
            NoirUtils.packBoundedVecU8(publicInputs.xHandleCapture1, X_HANDLE_CAPTURE_1_NUM_FIELDS)
        );
        fields.splice(
            SENDER_DOMAIN_CAPTURE_1_OFFSET,
            NoirUtils.packBoundedVecU8(publicInputs.senderDomainCapture1, SENDER_DOMAIN_CAPTURE_1_NUM_FIELDS)
        );
        return fields;
    }

    function _unpackPublicInputs(bytes32[] calldata fields) internal pure returns (PublicInputs memory publicInputs) {
        if (fields.length != PUBLIC_INPUTS_LENGTH) revert InvalidPublicInputsLength();

        return PublicInputs({
            pubkeyHash: fields[PUBKEY_HASH_OFFSET],
            headerHash: NoirUtils.unpackHeaderHash(
                fields.slice(HEADER_HASH_OFFSET, HEADER_HASH_OFFSET + HEADER_HASH_NUM_FIELDS)
            ),
            proverAddress: NoirUtils.unpackFieldsArray(
                fields.slice(PROVER_ADDRESS_OFFSET, PROVER_ADDRESS_OFFSET + PROVER_ADDRESS_NUM_FIELDS)
            ),
            command: NoirUtils.unpackFieldsArray(fields.slice(COMMAND_OFFSET, COMMAND_OFFSET + COMMAND_NUM_FIELDS)),
            xHandleCapture1: NoirUtils.unpackBoundedVecU8(
                fields.slice(X_HANDLE_CAPTURE_1_OFFSET, X_HANDLE_CAPTURE_1_OFFSET + X_HANDLE_CAPTURE_1_NUM_FIELDS)
            ),
            senderDomainCapture1: NoirUtils.unpackBoundedVecU8(
                fields.slice(
                    SENDER_DOMAIN_CAPTURE_1_OFFSET, SENDER_DOMAIN_CAPTURE_1_OFFSET + SENDER_DOMAIN_CAPTURE_1_NUM_FIELDS
                )
            )
        });
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
                value: publicInputs.xHandleCapture1,
                // header hash is used as nullifier
                nullifier: publicInputs.headerHash
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
