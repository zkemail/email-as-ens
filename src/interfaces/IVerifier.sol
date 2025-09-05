// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IVerifier {
    function verify(bytes memory data) external view returns (bool);
    function dkimRegistryAddress() external view returns (address);
    function encode(uint256[] memory publicSignals, bytes memory proof) external view returns (bytes memory);
}
