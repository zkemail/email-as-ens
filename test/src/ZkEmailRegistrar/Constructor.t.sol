// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { ZkEmailRegistrar } from "../../../src/ZkEmailRegistrar.sol";

contract ConstructorTest is Test {
    function test_setsCorrectValues() public {
        bytes32 rootNode = keccak256(bytes("rootNode"));
        address verifier = makeAddr("verifier");
        address ens = makeAddr("ens");

        ZkEmailRegistrar registrar = new ZkEmailRegistrar(rootNode, verifier, ens);

        assertEq(registrar.ROOT_NODE(), rootNode);
        assertEq(registrar.VERIFIER(), verifier);
        assertEq(registrar.REGISTRY(), ens);
    }
}
