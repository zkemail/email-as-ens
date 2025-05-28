// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { TestFixtures } from "./fixtures/TestFixtures.sol";
import { ProveAndClaimCommand, ProveAndClaimCommandVerifier } from "../src/utils/Verifier.sol";
import { Groth16Verifier } from "./fixtures/Groth16Verifier.sol";

contract VerifierTest is ProveAndClaimCommandVerifier {
    constructor() ProveAndClaimCommandVerifier(address(0)) { }

    function buildPubSignals(ProveAndClaimCommand memory command) public pure returns (uint256[60] memory) {
        return _buildPubSignals(command);
    }
}

contract FixturesTest is Test {
    ProveAndClaimCommandVerifier _verifier;

    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));
    }

    function test_buildPublicSignals_correctlyBuildsSignalsFromCommand() public {
        ProveAndClaimCommand memory command;
        uint256[60] memory expectedPubSignals;
        (command, expectedPubSignals) = TestFixtures.claimEnsCommand();

        VerifierTest verifier = new VerifierTest();
        uint256[60] memory publicSignals = verifier.buildPubSignals(command);

        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }
}
