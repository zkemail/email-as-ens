// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleCommand } from "./verifiers/LinkXHandleCommandVerifier.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { EnsUtils } from "./utils/EnsUtils.sol";
import { IEntryPoint } from "./interfaces/IEntryPoint.sol";
import { ITextRecordVerifier } from "./interfaces/ITextRecordVerifier.sol";

/**
 * @title LinkXHandleVerifier
 * @notice Verifies a LinkXHandleCommand and set the mapping of namehash(ensName) to x handle.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkXHandleVerifier is IEntryPoint, ITextRecordVerifier {
    using EnsUtils for bytes;

    bytes32 private immutable _X_HANDLE_KEY = keccak256(bytes("com.twitter"));

    // link x handle command verifier
    address public immutable VERIFIER;

    // can only be updated via the entrypoint function with a valid command
    mapping(bytes32 node => string xHandle) public xHandle;
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event XHandleSet(bytes32 indexed node, string xHandle);

    error InvalidCommand();
    error NullifierUsed();

    constructor(address verifier) {
        VERIFIER = verifier;
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Specifically decodes data as LinkXHandleCommand, validates proof and nullifier,
     *      then maps the ENS name hash to the x handle
     */
    function entrypoint(bytes memory data) external {
        LinkXHandleCommand memory command = abi.decode(data, (LinkXHandleCommand));
        _validate(command);

        bytes32 node = bytes(command.ensName).namehash();
        xHandle[node] = command.xHandle;
        emit XHandleSet(node, command.xHandle);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Delegates encoding to the configured VERIFIER contract
     */
    function encode(uint256[] calldata publicSignals, bytes calldata proof) external view returns (bytes memory) {
        return IVerifier(VERIFIER).encode(publicSignals, proof);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Returns the address of the DKIM registry
     */
    function dkimRegistryAddress() external view returns (address) {
        return IVerifier(VERIFIER).dkimRegistryAddress();
    }

    /**
     * @inheritdoc ITextRecordVerifier
     */
    function verifyTextRecord(bytes32 node, string memory key, string memory value) external view returns (bool) {
        // this verifier only supports x handle text record
        if (keccak256(bytes(key)) != _X_HANDLE_KEY) {
            revert UnsupportedKey();
        }
        string memory storedXHandle = xHandle[node];
        return keccak256(bytes(storedXHandle)) == keccak256(bytes(value));
    }

    function _validate(LinkXHandleCommand memory command) internal view {
        // bytes32 emailNullifier = command.proof.fields.emailNullifier;
        // if (_isUsed[emailNullifier]) {
        //     revert NullifierUsed();
        // }
        // _isUsed[emailNullifier] = true;

        if (!IVerifier(VERIFIER).verify(abi.encode(command))) {
            revert InvalidCommand();
        }
    }
}
