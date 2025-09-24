// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleCommandTestFixture } from "../../../fixtures/linkXHandleCommand/LinkXHandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/linkXHandleCommand/files/HonkVerifier.sol";
import { DKIMRegistryMock } from "../../../fixtures/DKIMRegistryMock.sol";
import {
    LinkXHandleCommand,
    LinkXHandleCommandVerifier,
    PublicInputs
} from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkXHandleCommandVerifier internal _verifier;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        _verifier = new LinkXHandleCommandVerifier(address(new HonkVerifier()), address(dkim));
        // configure DKIM mock with valid domain+key
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        dkim.setValid(
            keccak256(bytes(command.publicInputs.senderDomainCapture1)), command.publicInputs.pubkeyHash, true
        );
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkXHandleCommandTestFixture.getFixture();

        bytes memory encodedData = _verifier.encode(command.proof, expectedPublicInputs);
        LinkXHandleCommand memory decodedCommand = abi.decode(encodedData, (LinkXHandleCommand));

        _assertEq(decodedCommand.publicInputs, command.publicInputs);
    }

    function _assertEq(PublicInputs memory publicInputs, PublicInputs memory expectedPublicInputs) internal pure {
        assertEq(publicInputs.pubkeyHash, expectedPublicInputs.pubkeyHash, "Pubkey hash mismatch");
        assertEq(publicInputs.headerHash, expectedPublicInputs.headerHash, "Header hash mismatch");
        assertEq(publicInputs.proverAddress, expectedPublicInputs.proverAddress, "Prover address mismatch");
        assertEq(publicInputs.command, expectedPublicInputs.command, "Command mismatch");
        assertEq(publicInputs.xHandleCapture1, expectedPublicInputs.xHandleCapture1, "X handle capture 1 mismatch");
    }
}
