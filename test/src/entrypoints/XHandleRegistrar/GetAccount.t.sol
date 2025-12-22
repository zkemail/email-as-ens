// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";

contract GetAccountTest is XHandleRegistrarTest {
    function test_ReturnsAddressAfterDeployment() public {
        address predictedAddr = _registrar.predictAddress(_ensNode);
        _registrar.entrypoint(_validEncodedCommand);

        assertEq(_registrar.getAccount(_ensNode), predictedAddr, "Should return deployed account address");
    }

    function test_ReturnsZeroBeforeDeployment() public view {
        bytes32 testNode = keccak256("nonexistent");
        assertEq(_registrar.getAccount(testNode), address(0), "Should return zero for non-existent account");
    }
}

