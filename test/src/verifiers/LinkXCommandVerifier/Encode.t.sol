// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXTestFixture } from "../../../fixtures/LinkXTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/HonkVerifier.sol";
import { DKIMRegistryMock } from "../../../fixtures/DKIMRegistryMock.sol";
import { LinkXCommand, LinkXCommandVerifier, PubSignals } from "../../../../src/verifiers/LinkXCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkXCommandVerifier internal _verifier;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        _verifier = new LinkXCommandVerifier(address(new HonkVerifier()), address(dkim));
        (LinkXCommand memory command,) = LinkXTestFixture.linkXCommand();
        // TODO: use actual domain name
        dkim.setValid(keccak256(bytes("domainName")), command.pubSignals.pubkeyHash, true);
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkXCommand memory command, bytes32[] memory expectedPubSignals) = LinkXTestFixture.linkXCommand();

        bytes memory encodedData = _verifier.encode(command.proofFields, expectedPubSignals);
        LinkXCommand memory decodedCommand = abi.decode(encodedData, (LinkXCommand));

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
