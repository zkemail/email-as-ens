// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { EmailAuthVerifierHelper } from "./_EmailAuthVerifierHelper.sol";

contract DkimRegistryAddressTest is Test {
    function test_returnsCorrectAddress() public {
        address groth16Verifier = makeAddr("groth16Verifier");
        address dkimRegistry = makeAddr("dkimRegistry");
        EmailAuthVerifierHelper helper = new EmailAuthVerifierHelper(groth16Verifier, dkimRegistry);

        address result = helper.dkimRegistryAddress();
        assertEq(result, dkimRegistry);
    }
}
