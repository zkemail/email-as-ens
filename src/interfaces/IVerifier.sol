// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IVerifier {
    function verify(bytes memory data) external view returns (bool);
    function encode(uint256[] memory publicSignals, bytes memory proof) external pure returns (bytes memory);
}
