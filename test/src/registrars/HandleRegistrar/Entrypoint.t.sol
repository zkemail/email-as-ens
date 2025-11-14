// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { HandleRegistrarTest } from "./_HandleRegistrarTest.sol";

contract EntrypointTest is HandleRegistrarTest {
    function test_CallsClaimAndWithdraw() public {
        // Pre-fund the predicted address
        address predictedAddr = _registrar.predictAddress(_ensNode);
        uint256 fundAmount = 1 ether;
        vm.deal(predictedAddr, fundAmount);

        // Call entrypoint
        _registrar.entrypoint(_validEncodedCommand);

        // Verify account was created
        assertEq(_registrar.getAccount(_ensNode), predictedAddr, "Account should be created via entrypoint");

        // Verify withdrawal happened
        assertEq(_validCommand.target.balance, fundAmount, "ETH should be withdrawn via entrypoint");
    }
}

