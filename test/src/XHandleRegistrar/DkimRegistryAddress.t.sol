// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";

contract DkimRegistryAddressTest is XHandleRegistrarTest {
    function test_ReturnsCorrectAddress() public view {
        assertEq(_registrar.dkimRegistryAddress(), _dkimRegistry, "Should return correct DKIM registry address");
    }
}

