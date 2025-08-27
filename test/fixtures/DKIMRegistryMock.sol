// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract DKIMRegistryMock is IDKIMRegistry {
    mapping(bytes32 domainHash => mapping(bytes32 keyHash => bool isValid)) private _isValid;

    function setValid(bytes32 domainHash, bytes32 keyHash, bool valid) external {
        _isValid[domainHash][keyHash] = valid;
    }

    function isKeyHashValid(bytes32 domainHash, bytes32 keyHash) external view override returns (bool) {
        return _isValid[domainHash][keyHash];
    }
}
