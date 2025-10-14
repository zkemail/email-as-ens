// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { Groth16Verifier } from "../../../fixtures/Groth16Verifier.sol";
import { EnsUtils } from "../../../../src/utils/EnsUtils.sol";
import { LinkEmailEntrypointHelper } from "./_LinkEmailEntrypointHelper.sol";
import { LinkTextRecordEntrypoint } from "../../../../src/entrypoints/LinkTextRecordEntrypoint.sol";
import { TestUtils } from "../../../TestUtils.sol";

contract LinkEmailEntrypointTest is TestUtils {
    using EnsUtils for bytes;

    LinkEmailCommandVerifier public verifier;
    LinkEmailEntrypointHelper public linkEmail;

    function setUp() public {
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        address dkimRegistry = _createMockDkimRegistry(
            command.emailAuthProof.publicInputs.domainName, command.emailAuthProof.publicInputs.publicKeyHash
        );
        verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()), dkimRegistry);
        linkEmail = new LinkEmailEntrypointHelper(address(verifier));
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
        vm.expectRevert(abi.encodeWithSelector(LinkTextRecordEntrypoint.NullifierUsed.selector));
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
