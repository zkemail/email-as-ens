// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkXHandleCommandTestFixture } from "../../../fixtures/linkXHandleCommand/LinkXHandleCommandTestFixture.sol";
import { LinkXHandleCommand } from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { LinkXHandleCommandVerifierHelper } from "./_LinkXHandleCommandVerifierHelper.sol";

contract BuildPubSignalsTest is Test {
    LinkXHandleCommandVerifierHelper internal _verifier;

    function setUp() public {
        _verifier = new LinkXHandleCommandVerifierHelper();
    }

    function test_correctlyBuildsSignalsForLinkXHandleCommand() public view {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPubSignals) =
            LinkXHandleCommandTestFixture.getFixture();
        bytes32[] memory pubSignals = _verifier.packPubSignals(command.pubSignals);
        _assertPubSignals(pubSignals, expectedPubSignals);
    }

    function _assertPubSignals(bytes32[] memory pubSignals, bytes32[] memory expectedPubSignals) internal pure {
        assertEq(keccak256(abi.encode(pubSignals)), keccak256(abi.encode(expectedPubSignals)));
    }
}
