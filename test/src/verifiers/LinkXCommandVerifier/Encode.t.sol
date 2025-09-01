// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { console } from "forge-std/console.sol";
import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { HonkVerifier } from "../../../fixtures/HonkVerifier.sol";
import { LinkXCommand, LinkXCommandVerifier } from "../../../../src/verifiers/LinkXCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkXCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new LinkXCommandVerifier(address(new HonkVerifier()));
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkXCommand memory command, uint256[72] memory expectedPubSignals) = TestFixtures.linkXCommand();

        uint256[] memory publicSignals = new uint256[](72);
        for (uint256 i = 0; i < 72; i++) {
            publicSignals[i] = expectedPubSignals[i];
        }

        bytes memory encodedData = _verifier.encode(publicSignals, command.proof.proof);
        LinkXCommand memory decodedCommand = abi.decode(encodedData, (LinkXCommand));

        console.logBytes32(decodedCommand.proof.fields.pubkeyHash);
        console.logBytes32(decodedCommand.proof.fields.headerHash0);
        console.logBytes32(decodedCommand.proof.fields.headerHash1);
        console.logString(decodedCommand.proof.fields.proverAddress);
        console.logString(decodedCommand.proof.fields.owner);
        console.logString(decodedCommand.proof.fields.xHandleCapture1);

        // strings look the same but decoded len 1985 expected 6 ??
        console.log(bytes(decodedCommand.proof.fields.xHandleCapture1).length);
        console.log(bytes(command.proof.fields.xHandleCapture1).length);
        console.logBytes(bytes(decodedCommand.proof.fields.xHandleCapture1));
        console.logBytes(bytes(command.proof.fields.xHandleCapture1));

        assertEq(decodedCommand.proof.fields.pubkeyHash, command.proof.fields.pubkeyHash);
        assertEq(decodedCommand.proof.fields.headerHash0, command.proof.fields.headerHash0);
        assertEq(decodedCommand.proof.fields.headerHash1, command.proof.fields.headerHash1);
        assertEq(decodedCommand.proof.fields.proverAddress, command.proof.fields.proverAddress);
        assertEq(decodedCommand.proof.fields.owner, command.proof.fields.owner);
        assertEq(decodedCommand.proof.fields.xHandleCapture1, command.proof.fields.xHandleCapture1);
    }
}
