// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { Groth16Verifier } from "../../fixtures/Groth16Verifier.sol";
import { EnsUtils } from "../../../src/utils/EnsUtils.sol";
import { LinkEmailHelper } from "./_LinkEmailHelper.sol";
import { LinkEmail } from "../../../src/LinkEmail.sol";

contract LinkEmailTest is Test {
    using EnsUtils for bytes;

    LinkEmailCommandVerifier public verifier;
    LinkEmailHelper public linkEmail;

    function setUp() public {
        verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()));
        linkEmail = new LinkEmailHelper(address(verifier));
    }

    function test_entrypoint_correctlyEncodesAndValidatesCommand() public {
        (LinkEmailCommand memory command, uint256[60] memory pubSignals) = TestFixtures.linkEmailCommand();

        bytes memory encodedCommand = linkEmail.encode(_toDynamicArray(pubSignals), command.proof.proof);
        assertEq(linkEmail.link(bytes(command.email).namehash()), "");
        linkEmail.entrypoint(encodedCommand);
        assertEq(linkEmail.isUsed(command.proof.fields.emailNullifier), true);
        assertEq(linkEmail.link(bytes(command.email).namehash()), command.email);
    }

    function test_entrypoint_revertsWhenNullifierIsUsed() public {
        (LinkEmailCommand memory command, uint256[60] memory pubSignals) = TestFixtures.linkEmailCommand();
        bytes memory encodedCommand = linkEmail.encode(_toDynamicArray(pubSignals), command.proof.proof);
        linkEmail.entrypoint(encodedCommand);
        vm.expectRevert(abi.encodeWithSelector(LinkEmail.NullifierUsed.selector));
        linkEmail.entrypoint(encodedCommand);
    }

    function _toDynamicArray(uint256[60] memory pubSignals) internal pure returns (uint256[] memory) {
        uint256[] memory pubSignalsArray = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            pubSignalsArray[i] = pubSignals[i];
        }
        return pubSignalsArray;
    }
}
