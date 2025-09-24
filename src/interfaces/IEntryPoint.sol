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
     * @param proof The ZK proof bytes
     * @param publicInputs The public inputs for the ZK proof
     * @return The ABI-encoded data constructed from the public signals and proof
     * @dev It allows off-chain services (like a relayer) to construct the data payload
     *      required by the `entrypoint` function without coupling to the verifier's internal
     *      encoding logic.
     */
    function encode(bytes calldata proof, bytes32[] calldata publicInputs) external view returns (bytes memory);

    /**
     * @notice Returns the address of the DKIM registry
     * @return The address of the DKIM registry
     * @dev This is used (by the relayer) to check if the DKIM registry is valid for the given domain and update it if
     * needed
     */
    function dkimRegistryAddress() external view returns (address);
}
