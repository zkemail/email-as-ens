// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ZkEmailRegistrar } from "../../../src/ZkEmailRegistrar.sol";

contract ZkEmailRegistrarHelper is ZkEmailRegistrar {
    constructor(bytes32 rootNode, address verifier, address ens) ZkEmailRegistrar(rootNode, verifier, ens) { }

    function claim(string[] memory domainParts, address owner) public {
        _claim(domainParts, owner);
    }
}
