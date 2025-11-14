// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { HandleRegistrarTest } from "./_HandleRegistrarTest.sol";

contract DkimRegistryAddressTest is HandleRegistrarTest {
    function test_ReturnsCorrectAddress() public view {
        assertEq(_registrar.dkimRegistryAddress(), _dkimRegistry, "Should return correct DKIM registry address");
    }
}

