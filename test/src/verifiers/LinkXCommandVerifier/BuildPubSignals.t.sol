// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkXTestFixture } from "../../../fixtures/LinkXTestFixture.sol";
import { LinkXCommand } from "../../../../src/verifiers/LinkXCommandVerifier.sol";
import { LinkXCommandVerifierHelper } from "./_LinkXCommandVerifierHelper.sol";

contract BuildPubSignalsTest is Test {
    LinkXCommandVerifierHelper internal _verifier;

    function setUp() public {
        _verifier = new LinkXCommandVerifierHelper();
    }

    function test_correctlyBuildsSignalsForLinkXCommand() public view {
        (LinkXCommand memory command, bytes32[] memory expectedPubSignals) = LinkXTestFixture.linkXCommand();
        bytes32[] memory pubSignals = _verifier.packPubSignals(command.pubSignals);
        _assertPubSignals(pubSignals, expectedPubSignals);
    }

    function _assertPubSignals(bytes32[] memory pubSignals, bytes32[] memory expectedPubSignals) internal pure {
        assertEq(keccak256(abi.encode(pubSignals)), keccak256(abi.encode(expectedPubSignals)));
    }
}
