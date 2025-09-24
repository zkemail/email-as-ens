// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { ProveAndClaimCommand } from "../../../../src/verifiers/ProveAndClaimCommandVerifier.sol";
import { LinkEmailCommand } from "../../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { EmailAuthVerifierHelper } from "./_EmailAuthVerifierHelper.sol";

contract BuildPublicInputsTest is Test {
    EmailAuthVerifierHelper internal _verifier;

    function setUp() public {
        _verifier = new EmailAuthVerifierHelper();
    }

    function test_correctlyBuildsSignalsForClaimEnsCommand() public view {
        (ProveAndClaimCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.claimEnsCommand();
        bytes32[] memory publicInputs = _verifier.packPublicInputs(command.emailAuthProof.publicInputs);
        _assertEq(publicInputs, expectedPublicInputs);
    }

    function test_correctlyBuildsSignalsForLinkEmailCommand() public view {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes32[] memory publicInputs = _verifier.packPublicInputs(command.emailAuthProof.publicInputs);
        _assertEq(publicInputs, expectedPublicInputs);
    }

    function _assertEq(bytes32[] memory fields, bytes32[] memory expectedFields) internal pure {
        assertEq(keccak256(abi.encode(fields)), keccak256(abi.encode(expectedFields)));
    }
}
