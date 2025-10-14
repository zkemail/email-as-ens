// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";

/**
 * @title TestUtils
 * @notice Provides utility functions for testing
 */
contract TestUtils is Test {
    /**
     * @notice Mocks a function call and expects it to be called
     * @dev This function is used to mock a function call and expect it to be called
     * @param _target The address of the target contract
     * @param _call The call data
     * @param _ret The return data
     */
    function _mockAndExpect(address _target, bytes memory _call, bytes memory _ret) internal {
        vm.mockCall(_target, _call, _ret);
        vm.expectCall(_target, _call);
    }
}
