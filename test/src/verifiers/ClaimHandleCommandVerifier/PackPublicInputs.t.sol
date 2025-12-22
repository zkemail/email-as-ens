// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { HandleCommandTestFixture } from "../../../fixtures/handleCommand/HandleCommandTestFixture.sol";
import { ClaimHandleCommand } from "../../../../src/verifiers/ClaimHandleCommandVerifier.sol";
import { ClaimHandleCommandVerifierHelper } from "./_ClaimHandleCommandVerifierHelper.sol";

contract PackPublicInputsTest is Test {
    ClaimHandleCommandVerifierHelper internal _verifier;

    function setUp() public {
        address honkVerifier = makeAddr("honkVerifier");
        address dkimRegistry = makeAddr("dkimRegistry");
        _verifier = new ClaimHandleCommandVerifierHelper(honkVerifier, dkimRegistry);
    }

    function test_correctlyPacksPublicInputsForClaimHandleCommand() public view {
        (ClaimHandleCommand memory command, bytes32[] memory expectedPublicInputs) =
            HandleCommandTestFixture.getClaimXFixture();
        bytes32[] memory publicInputs = _verifier.packPublicInputs(command.publicInputs);
        _assertEq(publicInputs, expectedPublicInputs);
    }

    function _assertEq(bytes32[] memory fields, bytes32[] memory expectedFields) internal pure {
        assertEq(keccak256(abi.encode(fields)), keccak256(abi.encode(expectedFields)));
    }
}
