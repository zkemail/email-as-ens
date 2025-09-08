// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXTestFixture } from "../../../fixtures/LinkXTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/HonkVerifier.sol";
import { LinkXCommand, LinkXCommandVerifier, PubSignals } from "../../../../src/verifiers/LinkXCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";
import { BoundedVec, Field, FieldArray } from "../../../../src/utils/NoirUtils.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkXCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new LinkXCommandVerifier(address(new HonkVerifier()));
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkXCommand memory command, bytes32[] memory expectedPubSignals) = LinkXTestFixture.linkXCommand();

        bytes memory encodedData = _verifier.encode(command.proof, expectedPubSignals);
        LinkXCommand memory decodedCommand = abi.decode(encodedData, (LinkXCommand));

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
        _assertFieldArrayEq(
            decodedPubSignals.proverAddress, expectedPubSignals.proverAddress, "Prover address mismatch"
        );
        _assertFieldArrayEq(
            decodedPubSignals.maskedCommand, expectedPubSignals.maskedCommand, "Masked command mismatch"
        );
        _assertBoundedVecEq(
            decodedPubSignals.xHandleCapture1, expectedPubSignals.xHandleCapture1, "X handle capture 1 mismatch"
        );
    }

    function _assertFieldArrayEq(
        FieldArray memory decodedFields,
        FieldArray memory expectedFields,
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
