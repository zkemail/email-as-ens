// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { Groth16Verifier } from "../../fixtures/Groth16Verifier.sol";
import { DKIMRegistryMock } from "../../fixtures/DKIMRegistryMock.sol";
import { EnsUtils } from "../../../src/utils/EnsUtils.sol";
import { LinkEmailVerifierHelper } from "./_LinkEmailVerifierHelper.sol";
import { LinkTextRecordVerifier } from "../../../src/LinkTextRecordVerifier.sol";

contract LinkEmailVerifierTest is Test {
    using EnsUtils for bytes;

    LinkEmailCommandVerifier public verifier;
    LinkEmailVerifierHelper public linkEmail;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()), address(dkim));
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        dkim.setValid(
            keccak256(bytes(command.emailAuthProof.publicInputs.domainName)),
            command.emailAuthProof.publicInputs.publicKeyHash,
            true
        );
        linkEmail = new LinkEmailVerifierHelper(address(verifier));
    }

    function test_entrypoint_correctlyEncodesAndValidatesCommand() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();

        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        assertEq(linkEmail.textRecord(bytes(command.textRecord.ensName).namehash()), "");
        linkEmail.entrypoint(encodedCommand);
        assertEq(linkEmail.isUsed(command.emailAuthProof.publicInputs.emailNullifier), true);
        assertEq(linkEmail.textRecord(bytes(command.textRecord.ensName).namehash()), command.textRecord.value);
    }

    function test_entrypoint_revertsWhenNullifierIsUsed() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        linkEmail.entrypoint(encodedCommand);
        vm.expectRevert(abi.encodeWithSelector(LinkTextRecordVerifier.NullifierUsed.selector));
        linkEmail.entrypoint(encodedCommand);
    }

    function test_verifyTextRecord_returnsTrueWhenTextRecordIsCorrect() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        linkEmail.entrypoint(encodedCommand);
        assertEq(
            linkEmail.verifyTextRecord(bytes(command.textRecord.ensName).namehash(), "email", command.textRecord.value),
            true
        );
    }

    function test_verifyTextRecord_returnsFalseWhenTextRecordIsIncorrect() public {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(command.emailAuthProof.proof, expectedPublicInputs);
        linkEmail.entrypoint(encodedCommand);
        assertEq(
            linkEmail.verifyTextRecord(bytes(command.textRecord.ensName).namehash(), "email", "incorrect@e.com"), false
        );
    }
}
