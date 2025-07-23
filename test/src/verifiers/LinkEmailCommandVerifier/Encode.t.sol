// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { Groth16Verifier } from "../../../fixtures/Groth16Verifier.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkEmailCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()));
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkEmailCommand memory command, uint256[60] memory expectedPubSignals) = TestFixtures.linkEmailCommand();

        uint256[] memory publicSignals = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            publicSignals[i] = expectedPubSignals[i];
        }

        bytes memory encodedData = _verifier.encode(publicSignals, command.proof.proof);
        LinkEmailCommand memory decodedCommand = abi.decode(encodedData, (LinkEmailCommand));

        assertEq(decodedCommand.ensName, command.ensName);
        assertEq(decodedCommand.email, command.email);
        _assertDecodedFieldsEq(decodedCommand.proof.fields, command.proof.fields);
    }
}
