// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { EmailAuthVerifierHelper } from "./_EmailAuthVerifierHelper.sol";

contract DkimRegistryAddressTest is Test {
    function test_returnsCorrectAddress() public {
        address dkimRegistryAddress = makeAddr("dkimRegistry");
        EmailAuthVerifierHelper helper = new EmailAuthVerifierHelper(makeAddr("groth16Verifier"), dkimRegistryAddress);

        address result = helper.dkimRegistryAddress();
        assertEq(result, dkimRegistryAddress);
    }
}
