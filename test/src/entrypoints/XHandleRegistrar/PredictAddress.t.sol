// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";

contract PredictAddressTest is XHandleRegistrarTest {
    function test_ReturnsConsistentAddress() public view {
        bytes32 testNode = keccak256("testhandle");
        address predicted1 = _registrar.predictAddress(testNode);
        address predicted2 = _registrar.predictAddress(testNode);

        assertEq(predicted1, predicted2, "Predicted addresses should be consistent");
        assertTrue(predicted1 != address(0), "Predicted address should not be zero");
    }

    function test_DifferentNodesGiveDifferentAddresses() public view {
        bytes32 node1 = keccak256("handle1");
        bytes32 node2 = keccak256("handle2");

        address addr1 = _registrar.predictAddress(node1);
        address addr2 = _registrar.predictAddress(node2);

        assertTrue(addr1 != addr2, "Different nodes should predict different addresses");
    }
}

