// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkEmailCommand } from "./verifiers/LinkEmailCommandVerifier.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { EnsUtils } from "./utils/EnsUtils.sol";

/**
 * @title LinkEmailVerifier
 * @notice Verifies a LinkEmailCommand and set the mapping of namehash(ensName) to email address.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkEmailVerifier {
    using EnsUtils for bytes;

    address public immutable VERIFIER;

    mapping(bytes32 node => string emailAddress) public emailAddress; // can only be updated via the entrypoint function
        // with a valid command
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event EmailAddressSet(bytes32 indexed node, string emailAddress);

    error InvalidCommand();
    error NullifierUsed();

    constructor(address verifier) {
        VERIFIER = verifier;
    }

    /**
     * @notice Verifies a LinkEmailCommand and set the mapping of namehash(ensName) to email address.
     * @param data The ABI-encoded LinkEmailCommand struct.
     * @dev Expected to be constructed off-chain by calling `encode()` with the
     *      ZK proof's public signals and the proof itself. This function verifies the proof,
     *      and if valid, sets the mapping of namehash(ensName) to email address.
     */
    function entrypoint(bytes memory data) external {
        LinkEmailCommand memory command = abi.decode(data, (LinkEmailCommand));
        _validate(command);

        bytes32 node = bytes(command.ensName).namehash();
        emailAddress[node] = command.email;
        emit EmailAddressSet(node, command.email);
    }

    /**
     * @notice Exposes the encode function of the verifier contract.
     * @param publicSignals The public signals for the ZK proof.
     * @param proof The ZK proof bytes.
     * @return The ABI-encoded LinkEmailCommand struct constructed from the public signals and proof.
     * @dev This function is a convenience wrapper around the verifier's `encode` function.
     *      It allows off-chain services (like a relayer) to construct the data payload
     *      required by the `entrypoint` function without coupling to the verifier's internal
     *      encoding logic.
     */
    function encode(uint256[] calldata publicSignals, bytes calldata proof) external view returns (bytes memory) {
        return IVerifier(VERIFIER).encode(publicSignals, proof);
    }

    function _validate(LinkEmailCommand memory command) internal {
        bytes32 emailNullifier = command.proof.fields.emailNullifier;
        if (_isUsed[emailNullifier]) {
            revert NullifierUsed();
        }
        _isUsed[emailNullifier] = true;

        if (!IVerifier(VERIFIER).verify(abi.encode(command))) {
            revert InvalidCommand();
        }
    }
}
