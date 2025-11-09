// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { HandleRegistrarTest } from "./_HandleRegistrarTest.sol";

contract GetAccountTest is HandleRegistrarTest {
    function test_ReturnsAddressAfterDeployment() public {
        address predictedAddr = _registrar.predictAddress(_ensNode);
        _registrar.claimAndWithdraw(_validEncodedCommand);

        assertEq(_registrar.getAccount(_ensNode), predictedAddr, "Should return deployed account address");
    }

    function test_ReturnsZeroBeforeDeployment() public view {
        bytes32 testNode = keccak256("nonexistent");
        assertEq(_registrar.getAccount(testNode), address(0), "Should return zero for non-existent account");
    }
}

