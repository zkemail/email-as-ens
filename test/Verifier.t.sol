// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { TestFixtures } from "./fixtures/TestFixtures.sol";
import { ProveAndClaimCommand, ProveAndClaimCommandVerifier } from "../src/utils/Verifier.sol";
import { Groth16Verifier } from "./fixtures/Groth16Verifier.sol";

/**
 * @title PublicProveAndClaimCommandVerifier
 * @notice A test helper contract that exposes internal functions for testing
 * @dev This contract extends ProveAndClaimCommandVerifier to make internal functions public,
 *      allowing direct testing of the _buildPubSignals function without going through
 *      the complete verification process. Used specifically for unit testing the
 *      public signals construction logic.
 */
contract PublicProveAndClaimCommandVerifier is ProveAndClaimCommandVerifier {
    constructor() ProveAndClaimCommandVerifier(address(0)) { }

    function buildPubSignals(ProveAndClaimCommand memory command) public pure returns (uint256[60] memory) {
        return _buildPubSignals(command);
    }
}

/**
 * @title VerifierTest
 * @author ZK Email Team
 * @notice Test suite for the ProveAndClaimCommandVerifier contract
 */
contract VerifierTest is Test {
    /// @notice The verifier instance used for testing
    /// @dev Initialized with a real Groth16Verifier contract for complete integration testing
    ProveAndClaimCommandVerifier _verifier;

    /**
     * @notice Set up the test environment before each test
     * @dev Deploys a new ProveAndClaimCommandVerifier instance with a fresh Groth16Verifier
     *      contract. This ensures each test starts with a clean state.
     */
    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));
    }

    function test_buildPublicSignals_correctlyBuildsSignalsFromCommand() public {
        ProveAndClaimCommand memory command;
        uint256[60] memory expectedPubSignals;
        (command, expectedPubSignals) = TestFixtures.claimEnsCommand();

        PublicProveAndClaimCommandVerifier verifier = new PublicProveAndClaimCommandVerifier();
        uint256[60] memory publicSignals = verifier.buildPubSignals(command);

        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }

    function test_isValid_returnsTrueForValidCommand() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bool isValid = _verifier.isValid(abi.encode(command));
        assertTrue(isValid);
    }
}
