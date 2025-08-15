// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IDKIMRegistry.sol";

contract DKIMRegistryMock is IDKIMRegistry {
    mapping(string domainName => mapping(bytes32 publicKeyHash => bool isValid)) private _isValid;

    function setValid(string memory domainName, bytes32 publicKeyHash, bool valid) external {
        _isValid[domainName][publicKeyHash] = valid;
    }

    function isDKIMPublicKeyHashValid(
        string memory domainName,
        bytes32 publicKeyHash
    )
        external
        view
        override
        returns (bool)
    {
        return _isValid[domainName][publicKeyHash];
    }
}
