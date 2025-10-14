// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleCommandTestFixture } from "../../../fixtures/linkXHandleCommand/LinkXHandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/linkXHandleCommand/circuit/target/HonkVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { TestUtils } from "../../../TestUtils.sol";
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
        address dkimRegistry = makeAddr("dkimRegistry");
        _verifier = new LinkXHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
        // configure DKIM mock with valid domain+key
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        vm.mockCall(
            dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(command.publicInputs.senderDomain)),
                command.publicInputs.pubkeyHash
            ),
            abi.encode(true)
        );
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

    function _assertEq(PublicInputs memory publicInputs, PublicInputs memory expectedPublicInputs) internal pure {
        assertEq(publicInputs.pubkeyHash, expectedPublicInputs.pubkeyHash, "pubkeyHash mismatch");
        assertEq(publicInputs.headerHash, expectedPublicInputs.headerHash, "headerHash mismatch");
        assertEq(publicInputs.proverAddress, expectedPublicInputs.proverAddress, "proverAddress mismatch");
        assertEq(publicInputs.command, expectedPublicInputs.command, "command mismatch");
        assertEq(publicInputs.xHandle, expectedPublicInputs.xHandle, "xHandle mismatch");
        assertEq(publicInputs.senderDomain, expectedPublicInputs.senderDomain, "senderDomain mismatch");
        assertEq(publicInputs.nullifier, expectedPublicInputs.nullifier, "nullifier mismatch");
    }
}
