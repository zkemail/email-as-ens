// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { Groth16Verifier } from "../../../fixtures/Groth16Verifier.sol";
import { DKIMRegistryMock } from "../../../fixtures/DKIMRegistryMock.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../../src/verifiers/LinkEmailCommandVerifier.sol";

contract IsValidTest is Test {
    LinkEmailCommandVerifier internal _verifier;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        _verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()), address(dkim));
        // configure DKIM mock with valid domain+key
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        dkim.setValid(command.proof.fields.domainName, command.proof.fields.publicKeyHash, true);
    }

    function test_returnsFalseForInvalidProof() public view {
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(command.proof.proof, (uint256[2], uint256[2][2], uint256[2]));
        pA[0] = _verifier.Q();
        command.proof.proof = abi.encode(pA, pB, pC);
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsTrueForValidCommand() public view {
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        bool isValid = _verifier.verify(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForInvalidCommand() public view {
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        command.ensName = "wrong.eth";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }
}
