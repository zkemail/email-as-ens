// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXTestFixture } from "../../../fixtures/LinkXTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/HonkVerifier.sol";
import { Command, LinkXCommandVerifier, PubSignals } from "../../../../src/verifiers/LinkXCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";
import { Field, BoundedVec } from "../../../../src/utils/NoirUtils.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkXCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new LinkXCommandVerifier(address(new HonkVerifier()));
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (Command memory command, bytes32[] memory expectedPubSignals) = LinkXTestFixture.linkXCommand();

        bytes memory encodedData = _verifier.encode(command.proof, expectedPubSignals);
        Command memory decodedCommand = abi.decode(encodedData, (Command));

        _assertPubSignalsEq(decodedCommand.pubSignals, command.pubSignals);
    }

    function _assertPubSignalsEq(
        PubSignals memory decodedPubSignals,
        PubSignals memory expectedPubSignals
    )
        internal
        pure
    {
        _assertFieldEq(decodedPubSignals.pubkeyHash, expectedPubSignals.pubkeyHash, "Pubkey hash mismatch");
        _assertFieldEq(decodedPubSignals.headerHash0, expectedPubSignals.headerHash0, "Header hash 0 mismatch");
        _assertFieldEq(decodedPubSignals.headerHash1, expectedPubSignals.headerHash1, "Header hash 1 mismatch");
        _assertFieldsEq(decodedPubSignals.proverAddress, expectedPubSignals.proverAddress, "Prover address mismatch");
        _assertFieldsEq(decodedPubSignals.owner, expectedPubSignals.owner, "Owner mismatch");
        _assertBoundedVecEq(
            decodedPubSignals.xHandleCapture1, expectedPubSignals.xHandleCapture1, "X handle capture 1 mismatch"
        );
    }

    function _assertFieldsEq(
        Field[] memory decodedFields,
        Field[] memory expectedFields,
        string memory errorMessage
    )
        internal
        pure
    {
        assertEq(keccak256(abi.encode(decodedFields)), keccak256(abi.encode(expectedFields)), errorMessage);
    }

    function _assertBoundedVecEq(
        BoundedVec memory decodedBoundedVec,
        BoundedVec memory expectedBoundedVec,
        string memory errorMessage
    )
        internal
        pure
    {
        for (uint256 i = 0; i < decodedBoundedVec.elements.length; i++) {
            _assertFieldEq(
                decodedBoundedVec.elements[i],
                expectedBoundedVec.elements[i],
                string(abi.encodePacked(errorMessage, " at index ", vm.toString(i)))
            );
        }
        assertEq(
            decodedBoundedVec.maxLength,
            expectedBoundedVec.maxLength,
            string(abi.encodePacked(errorMessage, " at max length"))
        );
    }

    function _assertFieldEq(Field decodedField, Field expectedField, string memory errorMessage) internal pure {
        assertEq(keccak256(abi.encode(decodedField)), keccak256(abi.encode(expectedField)), errorMessage);
    }
}
