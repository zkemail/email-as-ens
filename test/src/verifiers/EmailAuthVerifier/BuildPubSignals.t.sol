// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { ProveAndClaimCommand } from "../../../../src/verifiers/ProveAndClaimCommandVerifier.sol";
import { LinkEmailCommand } from "../../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { EmailAuthVerifierHelper } from "./_EmailAuthVerifierHelper.sol";

contract BuildPubSignalsTest is Test {
    EmailAuthVerifierHelper internal _verifier;

    function setUp() public {
        _verifier = new EmailAuthVerifierHelper();
    }

    function test_correctlyBuildsSignalsForClaimEnsCommand() public view {
        (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals) = TestFixtures.claimEnsCommand();
        uint256[60] memory publicSignals = _verifier.packPubSignals(command.proof.fields);
        _assertPubSignals(publicSignals, expectedPubSignals);
    }

    function test_correctlyBuildsSignalsForLinkEmailCommand() public view {
        (LinkEmailCommand memory command, uint256[60] memory expectedPubSignals) = TestFixtures.linkEmailCommand();
        uint256[60] memory publicSignals = _verifier.packPubSignals(command.proof.fields);
        _assertPubSignals(publicSignals, expectedPubSignals);
    }

    function _assertPubSignals(uint256[60] memory publicSignals, uint256[60] memory expectedPubSignals) internal pure {
        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }
}
