// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrar } from "../../../src/XHandleRegistrar.sol";

contract XHandleRegistrarHelper is XHandleRegistrar {
    constructor(address verifier, bytes32 rootNode) XHandleRegistrar(verifier, rootNode) { }

    function isNullifierUsedExternal(bytes32 nullifier) external view returns (bool) {
        return _isUsed[nullifier];
    }
}

