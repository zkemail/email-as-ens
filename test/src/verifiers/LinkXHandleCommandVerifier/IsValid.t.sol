// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkXHandleTestFixture } from "../../../fixtures/LinkXHandleTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/HonkVerifier.sol";
import { DKIMRegistryMock } from "../../../fixtures/DKIMRegistryMock.sol";
import {
    LinkXHandleCommand, LinkXHandleCommandVerifier
} from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";

contract IsValidTest is Test {
    LinkXHandleCommandVerifier internal _verifier;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        _verifier = new LinkXHandleCommandVerifier(address(new HonkVerifier()), address(dkim));
        // configure DKIM mock with valid domain+key
        (LinkXHandleCommand memory command,) = LinkXHandleTestFixture.linkXHandleCommand();
        dkim.setValid(keccak256(bytes(command.pubSignals.senderDomainCapture1)), command.pubSignals.pubkeyHash, true);
    }

    // when verifier fails it reverts not returns false
    // TODO: figure this out
    // function test_returnsFalseForInvalidProof() public view {
    //     (LinkXHandleCommand memory command,) = LinkXHandleTestFixture.linkXHandleCommand();
    //     bytes memory proof = new bytes(command.proof.length);
    //     proof[0] = command.proof[0] ^ bytes1(uint8(1));
    //     command.proof = proof;
    //     bool isValid = _verifier.verify(abi.encode(command));
    //     assertFalse(isValid);
    // }

    function test_returnsTrueForValidCommand() public view {
        (LinkXHandleCommand memory command,) = LinkXHandleTestFixture.linkXHandleCommand();
        bool isValid = _verifier.verify(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForWrongENSName() public view {
        (LinkXHandleCommand memory command,) = LinkXHandleTestFixture.linkXHandleCommand();
        command.ensName = "wrong.eth";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsFalseForWrongXHandle() public view {
        (LinkXHandleCommand memory command,) = LinkXHandleTestFixture.linkXHandleCommand();
        command.xHandle = "wrong";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }
}
