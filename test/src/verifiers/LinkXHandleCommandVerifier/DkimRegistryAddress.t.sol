// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkXHandleCommandVerifierHelper } from "./_LinkXHandleCommandVerifierHelper.sol";

contract DkimRegistryAddressTest is Test {
    function test_returnsCorrectAddress() public {
        address honkVerifier = makeAddr("honkVerifier");
        address dkimRegistry = makeAddr("dkimRegistry");
        LinkXHandleCommandVerifierHelper helper = new LinkXHandleCommandVerifierHelper(honkVerifier, dkimRegistry);

        address result = helper.dkimRegistryAddress();
        assertEq(result, dkimRegistry);
    }
}
