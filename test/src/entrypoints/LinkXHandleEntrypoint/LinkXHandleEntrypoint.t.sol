// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {
    LinkXHandleCommand, LinkXHandleCommandVerifier
} from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { HonkVerifier } from "../../../fixtures/linkXHandleCommand/circuit/target/HonkVerifier.sol";
import { EnsUtils } from "../../../../src/utils/EnsUtils.sol";
import { LinkXHandleEntrypointHelper } from "./_LinkXHandleEntrypointHelper.sol";
import { LinkTextRecordEntrypoint } from "../../../../src/entrypoints/LinkTextRecordEntrypoint.sol";
import { LinkXHandleCommandTestFixture } from "../../../fixtures/linkXHandleCommand/LinkXHandleCommandTestFixture.sol";
import { TestUtils } from "../../../TestUtils.sol";

contract LinkXHandleVerifierTest is TestUtils {
    using EnsUtils for bytes;

    LinkXHandleCommandVerifier public verifier;
    LinkXHandleEntrypointHelper public linkXHandle;

    function setUp() public {
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        address dkimRegistry =
            _createMockDkimRegistry(command.publicInputs.senderDomain, command.publicInputs.pubkeyHash);
        verifier = new LinkXHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
        linkXHandle = new LinkXHandleEntrypointHelper(address(verifier));
    }

    function test_entrypoint_correctlyEncodesAndValidatesCommand() public {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkXHandleCommandTestFixture.getFixture();

        bytes memory encodedCommand = linkXHandle.encode(command.proof, expectedPublicInputs);
        assertEq(linkXHandle.textRecord(bytes(command.textRecord.ensName).namehash()), "");
        linkXHandle.entrypoint(encodedCommand);
        assertEq(linkXHandle.isUsed(command.publicInputs.nullifier), true);
        assertEq(linkXHandle.textRecord(bytes(command.textRecord.ensName).namehash()), command.textRecord.value);
    }

    function test_entrypoint_revertsWhenNullifierIsUsed() public {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkXHandleCommandTestFixture.getFixture();
        bytes memory encodedCommand = linkXHandle.encode(command.proof, expectedPublicInputs);
        linkXHandle.entrypoint(encodedCommand);
        vm.expectRevert(abi.encodeWithSelector(LinkTextRecordEntrypoint.NullifierUsed.selector));
        linkXHandle.entrypoint(encodedCommand);
    }

    function test_verifyTextRecord_returnsFalseWhenTextRecordIsIncorrect() public {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkXHandleCommandTestFixture.getFixture();
        bytes memory encodedCommand = linkXHandle.encode(command.proof, expectedPublicInputs);
        linkXHandle.entrypoint(encodedCommand);
        assertEq(
            linkXHandle.verifyTextRecord(bytes(command.textRecord.ensName).namehash(), "com.twitter", "incorrect"),
            false
        );
    }

    function test_verifyTextRecord_returnsTrueWhenTextRecordIsCorrect() public {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkXHandleCommandTestFixture.getFixture();
        bytes memory encodedCommand = linkXHandle.encode(command.proof, expectedPublicInputs);
        linkXHandle.entrypoint(encodedCommand);
        assertEq(
            linkXHandle.verifyTextRecord(
                bytes(command.textRecord.ensName).namehash(), "com.twitter", command.textRecord.value
            ),
            true
        );
    }
}
