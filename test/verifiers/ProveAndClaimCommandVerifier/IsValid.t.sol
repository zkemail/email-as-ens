// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { Groth16Verifier } from "../../fixtures/Groth16Verifier.sol";
import {
    ProveAndClaimCommand, ProveAndClaimCommandVerifier
} from "../../../src/verifiers/ProveAndClaimCommandVerifier.sol";

contract IsValidTest is Test {
    ProveAndClaimCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));
    }

    function test_returnsFalseForInvalidProof() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommandWithResolver();
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(command.proof.proof, (uint256[2], uint256[2][2], uint256[2]));
        pA[0] = _verifier.Q();
        command.proof.proof = abi.encode(pA, pB, pC);
        bool isValid = _verifier.isValid(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsTrueForValidCommandWithResolver() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommandWithResolver();
        bool isValid = _verifier.isValid(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForInvalidCommand() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommandWithResolver();
        string[] memory emailParts = new string[](2);
        emailParts[0] = "bob@example";
        emailParts[1] = "com";
        command.proof.fields.emailAddress = "bob@example.com";
        command.emailParts = emailParts;
        bool isValid = _verifier.isValid(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsFalseForInvalidEmailParts() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommandWithResolver();
        command.emailParts = new string[](1);
        command.emailParts[0] = "bob@example";
        bool isValid = _verifier.isValid(abi.encode(command));
        assertFalse(isValid);
    }
}
