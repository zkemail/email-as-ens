// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";

contract IsNullifierUsedTest is XHandleRegistrarTest {
    function test_ReturnsTrueAfterClaim() public {
        _registrar.entrypoint(_validEncodedCommand);
        assertTrue(
            _registrar.isNullifierUsed(_validCommand.publicInputs.emailNullifier), "Nullifier should be marked as used"
        );
    }

    function test_ReturnsFalseByDefault() public view {
        bytes32 testNullifier = keccak256("test");
        assertFalse(_registrar.isNullifierUsed(testNullifier), "Nullifier should not be used by default");
    }
}

