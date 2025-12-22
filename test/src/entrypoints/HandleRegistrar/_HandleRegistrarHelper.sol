// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { HandleRegistrar } from "../../../../src/entrypoints/HandleRegistrar.sol";

contract HandleRegistrarHelper is HandleRegistrar {
    constructor(address verifier, bytes32 rootNode) HandleRegistrar(verifier, rootNode) { }

    function isNullifierUsedExternal(bytes32 nullifier) external view returns (bool) {
        return _isUsed[nullifier];
    }
}

