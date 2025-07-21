// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { Groth16Verifier } from "../../fixtures/Groth16Verifier.sol";
import {
    ProveAndClaimCommand, ProveAndClaimCommandVerifier
} from "../../../src/verifiers/ProveAndClaimCommandVerifier.sol";

contract ProveAndClaimCommandVerifierHelper is ProveAndClaimCommandVerifier {
    constructor() ProveAndClaimCommandVerifier(address(0)) { }

    function buildPubSignals(ProveAndClaimCommand memory command) public pure returns (uint256[60] memory) {
        return _packPubSignals(command.proof.fields);
    }
}

contract BuildPubSignalsTest is Test {
    ProveAndClaimCommandVerifierHelper internal _verifier;

    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifierHelper();
    }

    function test_correctlyBuildsSignalsFromCommand() public view {
        ProveAndClaimCommand memory command;
        uint256[60] memory expectedPubSignals;
        (command, expectedPubSignals) = TestFixtures.claimEnsCommandWithResolver();

        uint256[60] memory publicSignals = _verifier.buildPubSignals(command);

        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }

    function test_correctlyBuildsSignalsFromCommandWithResolver() public view {
        (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals) =
            TestFixtures.claimEnsCommandWithResolver();

        uint256[60] memory publicSignals = _verifier.buildPubSignals(command);

        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }
}
