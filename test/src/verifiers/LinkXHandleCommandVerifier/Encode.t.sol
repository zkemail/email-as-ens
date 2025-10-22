// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleCommandTestFixture } from "../../../fixtures/linkXHandleCommand/LinkXHandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/linkXHandleCommand/circuit/target/HonkVerifier.sol";
import {
    LinkXHandleCommand,
    LinkXHandleCommandVerifier,
    PublicInputs,
    TextRecord
} from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkXHandleCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new LinkXHandleCommandVerifier(address(new HonkVerifier()), makeAddr("dkimRegistry"));
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkXHandleCommandTestFixture.getFixture();

        bytes memory encodedData = _verifier.encode(command.proof, expectedPublicInputs);
        LinkXHandleCommand memory decodedCommand = abi.decode(encodedData, (LinkXHandleCommand));

        _assertEq(decodedCommand.textRecord, command.textRecord);
        assertEq(decodedCommand.proof, command.proof, "proof mismatch");
        _assertEq(decodedCommand.publicInputs, command.publicInputs);
    }

    function _assertEq(TextRecord memory textRecord, TextRecord memory expectedTextRecord) internal pure {
        assertEq(textRecord.ensName, expectedTextRecord.ensName, "ENS name mismatch");
        assertEq(textRecord.value, expectedTextRecord.value, "value mismatch");
        assertEq(textRecord.nullifier, expectedTextRecord.nullifier, "nullifier mismatch");
    }

    function _assertEq(
        PublicInputs memory publicInputs,
        PublicInputs memory expectedPublicInputs
    )
        internal
        pure
    {
        assertEq(publicInputs.pubkeyHash, expectedPublicInputs.pubkeyHash, "pubkeyHash mismatch");
        assertEq(publicInputs.emailNullifier, expectedPublicInputs.emailNullifier, "nullifier mismatch");
        assertEq(publicInputs.headerHash, expectedPublicInputs.headerHash, "headerHash mismatch");
        assertEq(publicInputs.proverAddress, expectedPublicInputs.proverAddress, "proverAddress mismatch");
        assertEq(publicInputs.command, expectedPublicInputs.command, "command mismatch");
        assertEq(publicInputs.xHandle, expectedPublicInputs.xHandle, "xHandle mismatch");
        assertEq(publicInputs.senderDomain, expectedPublicInputs.senderDomain, "senderDomain mismatch");
    }
}
