// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title IVerifier
 * @notice Interface for the Verifier contract
 */
interface IVerifier {
    /**
     * @dev Returns the address of the DKIM registry
     * @return The address of the DKIM registry
     */
    function dkimRegistryAddress() external view returns (address);

    /**
     * @notice Encodes the proof and the public inputs fields into a bytes memory that can be used as input to `verify`
     * @param proof The proof bytes
     * @param publicInputs The public inputs array
     * @return encodedCommand The encoded command bytes
     */
    function encode(bytes memory proof, bytes32[] memory publicInputs) external view returns (bytes memory);

    /**
     * @notice Verifies the validity of given encoded data
     * @param data The ABI-encoded data. Can be obtained by calling `encode` with the public signals and proof.
     * @return isValid True if the proof is valid, false otherwise
     * @dev The encoded data is expected to be constructed off-chain by calling `encode` with the public signals and
     * proof.
     */
    function verify(bytes memory data) external view returns (bool);
}
