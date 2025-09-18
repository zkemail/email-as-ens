// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleTestFixture } from "../../../fixtures/LinkXHandleTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/HonkVerifier.sol";
import { DKIMRegistryMock } from "../../../fixtures/DKIMRegistryMock.sol";
import {
    LinkXHandleCommand,
    LinkXHandleCommandVerifier,
    PubSignals
} from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkXHandleCommandVerifier internal _verifier;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        _verifier = new LinkXHandleCommandVerifier(address(new HonkVerifier()), address(dkim));
        // configure DKIM mock with valid domain+key
        (LinkXHandleCommand memory command,) = LinkXHandleTestFixture.linkXHandleCommand();
        dkim.setValid(keccak256(bytes(command.pubSignals.senderDomainCapture1)), command.pubSignals.pubkeyHash, true);
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPubSignals) =
            LinkXHandleTestFixture.linkXHandleCommand();

        bytes memory encodedData = _verifier.encode(command.proofFields, expectedPubSignals);
        LinkXHandleCommand memory decodedCommand = abi.decode(encodedData, (LinkXHandleCommand));

        _assertPubSignalsEq(decodedCommand.pubSignals, command.pubSignals);
    }

    function _assertPubSignalsEq(
        PubSignals memory decodedPubSignals,
        PubSignals memory expectedPubSignals
    )
        internal
        pure
    {
        assertEq(decodedPubSignals.pubkeyHash, expectedPubSignals.pubkeyHash, "Pubkey hash mismatch");
        assertEq(decodedPubSignals.headerHash0, expectedPubSignals.headerHash0, "Header hash 0 mismatch");
        assertEq(decodedPubSignals.headerHash1, expectedPubSignals.headerHash1, "Header hash 1 mismatch");
        assertEq(decodedPubSignals.proverAddress, expectedPubSignals.proverAddress, "Prover address mismatch");
        assertEq(decodedPubSignals.command, expectedPubSignals.command, "Command mismatch");
        assertEq(decodedPubSignals.xHandleCapture1, expectedPubSignals.xHandleCapture1, "X handle capture 1 mismatch");
    }
}
