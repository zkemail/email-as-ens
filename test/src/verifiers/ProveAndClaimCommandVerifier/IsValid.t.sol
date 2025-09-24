// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { Groth16Verifier } from "../../../fixtures/Groth16Verifier.sol";
import { DKIMRegistryMock } from "../../../fixtures/DKIMRegistryMock.sol";
import {
    ProveAndClaimCommand,
    ProveAndClaimCommandVerifier
} from "../../../../src/verifiers/ProveAndClaimCommandVerifier.sol";

contract IsValidTest is Test {
    ProveAndClaimCommandVerifier internal _verifier;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()), address(dkim));
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        dkim.setValid(
            keccak256(bytes(command.emailAuthProof.publicInputs.domainName)),
            command.emailAuthProof.publicInputs.publicKeyHash,
            true
        );
    }

    function test_returnsFalseForInvalidProof() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(command.emailAuthProof.proof, (uint256[2], uint256[2][2], uint256[2]));
        pA[0] = _verifier.Q();
        command.emailAuthProof.proof = abi.encode(pA, pB, pC);
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsTrueForValidCommand() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bool isValid = _verifier.verify(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForInvalidCommand() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        string[] memory emailParts = new string[](2);
        emailParts[0] = "bob@example";
        emailParts[1] = "com";
        command.emailAuthProof.publicInputs.emailAddress = "bob@example.com";
        command.emailParts = emailParts;
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsFalseForInvalidEmailParts() public view {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        command.emailParts = new string[](1);
        command.emailParts[0] = "bob@example";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }
}
