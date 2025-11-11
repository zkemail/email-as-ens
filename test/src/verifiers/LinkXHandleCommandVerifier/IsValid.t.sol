// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkXHandleCommandTestFixture } from "../../../fixtures/handleCommand/LinkXHandleCommandTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/handleCommand/HonkVerifier.sol";
import {
    LinkXHandleCommand,
    LinkXHandleCommandVerifier
} from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract IsValidTest is Test {
    LinkXHandleCommandVerifier internal _verifier;

    function setUp() public {
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        address dkimRegistry = makeAddr("dkimRegistry");
        vm.mockCall(
            dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(command.publicInputs.senderDomain)),
                command.publicInputs.pubkeyHash
            ),
            abi.encode(true)
        );
        _verifier = new LinkXHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
    }

    // when verifier fails it reverts not returns false
    // expect revert for now
    // TODO: figure this out
    function test_revertsWhen_InvalidProof() public {
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        bytes memory proof = new bytes(command.proof.length);
        proof[0] = command.proof[0] ^ bytes1(uint8(1));
        command.proof = proof;
        vm.expectRevert();
        _verifier.verify(abi.encode(command));
    }

    function test_returnsTrueForValidCommand() public view {
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        bool isValid = _verifier.verify(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForWrongENSName() public view {
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        command.textRecord.ensName = "wrong.eth";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsFalseForWrongXHandle() public view {
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();
        command.textRecord.value = "wrong";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }
}
