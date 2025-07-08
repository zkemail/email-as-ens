// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "./fixtures/TestFixtures.sol";
import { ProveAndClaimCommand, ProveAndClaimCommandVerifier } from "../src/utils/Verifier.sol";
import { Groth16Verifier } from "./fixtures/Groth16Verifier.sol";
import { console } from "forge-std/console.sol";

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
    ProveAndClaimCommandVerifier internal _verifier;

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

    function test_buildPublicSignals_correctlyBuildsSignalsFromCommandWithResolver() public {
        (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals) =
            TestFixtures.claimEnsCommandWithResolver();

        PublicProveAndClaimCommandVerifier verifier = new PublicProveAndClaimCommandVerifier();
        uint256[60] memory publicSignals = verifier.buildPubSignals(command);

        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }

    function test_isValid_returnsFalseForInvalidProof() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(command.proof, (uint256[2], uint256[2][2], uint256[2]));
        pA[0] = _verifier.Q();
        command.proof = abi.encode(pA, pB, pC);
        bool isValid = _verifier.isValid(abi.encode(command));
        assertFalse(isValid);
    }

    function test_isValid_returnsTrueForValidCommand() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bool isValid = _verifier.isValid(abi.encode(command));
        assertTrue(isValid);
    }

    function test_isValid_returnsTrueForValidCommandWithResolver() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommandWithResolver();
        bool isValid = _verifier.isValid(abi.encode(command));
        assertTrue(isValid);
    }

    function test_isValid_returnsFalseForInvalidCommand() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        string[] memory emailParts = new string[](2);
        emailParts[0] = "bob@example";
        emailParts[1] = "com";
        command.email = "bob@example.com";
        command.emailParts = emailParts;
        bool isValid = _verifier.isValid(abi.encode(command));
        assertFalse(isValid);
    }

    function test_isValid_returnsFalseForInvalidEmailParts() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        command.emailParts = new string[](1);
        command.emailParts[0] = "bob@example";
        bool isValid = _verifier.isValid(abi.encode(command));
        assertFalse(isValid);
    }
}
