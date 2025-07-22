// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { ProveAndClaimCommand } from "../../../../src/verifiers/ProveAndClaimCommandVerifier.sol";
import { ProveAndClaimCommandVerifierHelper } from "./_ProveAndClaimCommandVerifierHelper.sol";

contract BuildPubSignalsTest is Test {
    ProveAndClaimCommandVerifierHelper internal _verifier;

    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifierHelper();
    }

    function test_correctlyBuildsSignalsFromCommand() public view {
        (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals) = TestFixtures.claimEnsCommand();

        uint256[60] memory publicSignals = _verifier.buildPubSignals(command);

        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }
}
