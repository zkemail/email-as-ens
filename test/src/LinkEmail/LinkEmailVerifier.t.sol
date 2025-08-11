// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { Groth16Verifier } from "../../fixtures/Groth16Verifier.sol";
import { DKIMRegistryMock } from "../../fixtures/DKIMRegistryMock.sol";
import { EnsUtils } from "../../../src/utils/EnsUtils.sol";
import { LinkEmailVerifierHelper } from "./_LinkEmailVerifierHelper.sol";
import { LinkEmailVerifier } from "../../../src/LinkEmailVerifier.sol";

contract LinkEmailVerifierTest is Test {
    using EnsUtils for bytes;

    LinkEmailCommandVerifier public verifier;
    LinkEmailVerifierHelper public linkEmail;

    function setUp() public {
        DKIMRegistryMock dkim = new DKIMRegistryMock();
        verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()), address(dkim));
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        dkim.setValid(keccak256(bytes(command.proof.fields.domainName)), command.proof.fields.publicKeyHash, true);
        linkEmail = new LinkEmailVerifierHelper(address(verifier));
    }

    function test_entrypoint_correctlyEncodesAndValidatesCommand() public {
        (LinkEmailCommand memory command, uint256[60] memory pubSignals) = TestFixtures.linkEmailCommand();

        bytes memory encodedCommand = linkEmail.encode(_toDynamicArray(pubSignals), command.proof.proof);
        assertEq(linkEmail.emailAddress(bytes(command.ensName).namehash()), "");
        linkEmail.entrypoint(encodedCommand);
        assertEq(linkEmail.isUsed(command.proof.fields.emailNullifier), true);
        assertEq(linkEmail.emailAddress(bytes(command.ensName).namehash()), command.email);
    }

    function test_entrypoint_revertsWhenNullifierIsUsed() public {
        (LinkEmailCommand memory command, uint256[60] memory pubSignals) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(_toDynamicArray(pubSignals), command.proof.proof);
        linkEmail.entrypoint(encodedCommand);
        vm.expectRevert(abi.encodeWithSelector(LinkEmailVerifier.NullifierUsed.selector));
        linkEmail.entrypoint(encodedCommand);
    }

    function test_verifyTextRecord_returnsTrueWhenTextRecordIsCorrect() public {
        (LinkEmailCommand memory command, uint256[60] memory pubSignals) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(_toDynamicArray(pubSignals), command.proof.proof);
        linkEmail.entrypoint(encodedCommand);
        assertEq(linkEmail.verifyTextRecord(bytes(command.ensName).namehash(), "email", command.email), true);
    }

    function test_verifyTextRecord_returnsFalseWhenTextRecordIsIncorrect() public {
        (LinkEmailCommand memory command, uint256[60] memory pubSignals) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(_toDynamicArray(pubSignals), command.proof.proof);
        linkEmail.entrypoint(encodedCommand);
        assertEq(linkEmail.verifyTextRecord(bytes(command.ensName).namehash(), "email", "incorrect@e.com"), false);
    }

    function _toDynamicArray(uint256[60] memory pubSignals) internal pure returns (uint256[] memory) {
        uint256[] memory pubSignalsArray = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            pubSignalsArray[i] = pubSignals[i];
        }
        return pubSignalsArray;
    }
}
