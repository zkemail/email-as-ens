// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { Groth16Verifier } from "../../../fixtures/Groth16Verifier.sol";
import {
    ProveAndClaimCommand,
    ProveAndClaimCommandVerifier
} from "../../../../src/verifiers/ProveAndClaimCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    ProveAndClaimCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals) = TestFixtures.claimEnsCommand();

        uint256[] memory publicSignals = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            publicSignals[i] = expectedPubSignals[i];
        }

        bytes memory encodedData = _verifier.encode(publicSignals, command.proof.proof);
        ProveAndClaimCommand memory decodedCommand = abi.decode(encodedData, (ProveAndClaimCommand));

        assertEq(decodedCommand.resolver, command.resolver);
        assertEq(decodedCommand.owner, command.owner);
        for (uint256 i = 0; i < decodedCommand.emailParts.length; i++) {
            assertEq(decodedCommand.emailParts[i], command.emailParts[i]);
        }
        _assertDecodedFieldsEq(decodedCommand.proof.fields, command.proof.fields);
    }
}
