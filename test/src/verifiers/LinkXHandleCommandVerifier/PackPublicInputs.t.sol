// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkXHandleCommandTestFixture } from "../../../fixtures/linkXHandleCommand/LinkXHandleCommandTestFixture.sol";
import { LinkXHandleCommand } from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { LinkXHandleCommandVerifierHelper } from "./_LinkXHandleCommandVerifierHelper.sol";

contract PackPublicInputsTest is Test {
    LinkXHandleCommandVerifierHelper internal _verifier;

    function setUp() public {
        address honkVerifier = makeAddr("honkVerifier");
        address dkimRegistry = makeAddr("dkimRegistry");
        _verifier = new LinkXHandleCommandVerifierHelper(honkVerifier, dkimRegistry);
    }

    function test_correctlyPacksPublicInputsForLinkXHandleCommand() public view {
        (LinkXHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            LinkXHandleCommandTestFixture.getFixture();
        bytes32[] memory publicInputs = _verifier.packPublicInputs(command.publicInputs);
        _assertEq(publicInputs, expectedPublicInputs);
    }

    function _assertEq(bytes32[] memory fields, bytes32[] memory expectedFields) internal pure {
        assertEq(keccak256(abi.encode(fields)), keccak256(abi.encode(expectedFields)));
    }
}
