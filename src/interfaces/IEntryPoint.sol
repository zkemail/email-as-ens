// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IEntryPoint
 * @notice Standard interface for contracts that expose entrypoint functions
 */
interface IEntryPoint {
    /**
     * @notice Entrypoint function for the contract
     * @param data Encoded data that can be decoded into any data type the EntryPoint contract expects
     * @dev The data is expected to be constructed off-chain by calling `encode()` with the
     *      ZK proof's public signals and the proof itself. This function verifies the proof,
     *      and if valid, executes the entrypoint logic.
     */
    function entrypoint(bytes memory data) external;

    /**
     * @notice Encodes the public signals and proof into bytes compatible with the entrypoint function
     * @param publicSignals The public signals for the ZK proof
     * @param proof The ZK proof bytes
     * @return The ABI-encoded data constructed from the public signals and proof
     * @dev It allows off-chain services (like a relayer) to construct the data payload
     *      required by the `entrypoint` function without coupling to the verifier's internal
     *      encoding logic.
     */
    function encode(uint256[] calldata publicSignals, bytes calldata proof) external view returns (bytes memory);
}
