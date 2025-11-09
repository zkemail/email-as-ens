// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { ClaimHandleCommandVerifierHelper } from "./_ClaimHandleCommandVerifierHelper.sol";

contract DkimRegistryAddressTest is Test {
    function test_returnsCorrectAddress() public {
        address honkVerifier = makeAddr("honkVerifier");
        address dkimRegistry = makeAddr("dkimRegistry");
        ClaimHandleCommandVerifierHelper helper = new ClaimHandleCommandVerifierHelper(honkVerifier, dkimRegistry);

        address result = helper.dkimRegistryAddress();
        assertEq(result, dkimRegistry);
    }
}
