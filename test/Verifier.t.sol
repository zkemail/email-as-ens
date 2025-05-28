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
    /**
     * @notice Initializes the test verifier with a zero address
     * @dev Uses address(0) for the Groth16 verifier since we only need to test
     *      the public signals building functionality, not the actual proof verification
     */
    constructor() ProveAndClaimCommandVerifier(address(0)) { }

    /**
     * @notice Exposes the internal _buildPubSignals function for testing
     * @param command The ProveAndClaimCommand struct to build public signals from
     * @return The 60-element array of public signals for ZK proof verification
     * @dev This function is used to test that the public signals are correctly constructed
     *      from a ProveAndClaimCommand struct without requiring a valid Groth16 verifier
     */
    function buildPubSignals(ProveAndClaimCommand memory command) public pure returns (uint256[60] memory) {
        return _buildPubSignals(command);
    }
}

/**
 * @title VerifierTest
 * @author ZK Email Team
 * @notice Test suite for the ProveAndClaimCommandVerifier contract
 * @dev This test suite validates the core functionality of the ZK Email ENS verifier,
 *      including public signals construction and complete proof verification.
 *
 *      Tests cover:
 *      - Correct construction of public signals from ProveAndClaimCommand structs
 *      - End-to-end proof verification with valid test data
 *      - Integration with the Groth16 verifier contract
 *
 *      The tests use pre-computed test data from TestFixtures to ensure consistency
 *      and avoid the need for generating live cryptographic proofs during testing.
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

    /**
     * @notice Tests that public signals are correctly built from a ProveAndClaimCommand
     * @dev This test verifies that the _buildPubSignals function correctly converts
     *      a ProveAndClaimCommand struct into the expected 60-element public signals array.
     *
     *      The test:
     *      1. Loads test data from TestFixtures (command and expected signals)
     *      2. Uses the test helper contract to call _buildPubSignals
     *      3. Compares each of the 60 elements to ensure exact matches
     *
     *      This validates that string packing, field element conversion, and signal
     *      ordering all work correctly according to the ZK circuit specification.
     */
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

    /**
     * @notice Tests that a valid command passes verification
     * @dev This test performs end-to-end verification of a valid ProveAndClaimCommand,
     *      ensuring that the complete verification pipeline works correctly.
     *
     *      The test:
     *      1. Loads a valid command with embedded ZK proof from TestFixtures
     *      2. ABI-encodes the command as it would be passed to the contract
     *      3. Calls isValid on the verifier to perform complete verification
     *      4. Asserts that verification returns true for the valid command
     *
     *      This validates the entire verification flow including:
     *      - Command decoding
     *      - Proof component extraction and validation
     *      - Public signals construction
     *      - Groth16 proof verification
     */
    function test_isValid_returnsTrueForValidCommand() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bool isValid = _verifier.isValid(abi.encode(command));
        assertTrue(isValid);
    }
}
