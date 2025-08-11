// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IDKIMRegistry {
    function isKeyHashValid(bytes32 domainHash, bytes32 keyHash) external view returns (bool);
}
