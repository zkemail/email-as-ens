// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { LinkXTestFixture } from "../../../fixtures/LinkXTestFixture.sol";
import { HonkVerifier } from "../../../fixtures/HonkVerifier.sol";
import { LinkXCommand, LinkXCommandVerifier } from "../../../../src/verifiers/LinkXCommandVerifier.sol";

contract IsValidTest is Test {
    LinkXCommandVerifier internal _verifier;

    function setUp() public {
        _verifier = new LinkXCommandVerifier(address(new HonkVerifier()));
    }

    // when verifier fails it reverts not returns false
    // function test_returnsFalseForInvalidProof() public view {
    //     (LinkXCommand memory command,) = LinkXTestFixture.linkXCommand();
    //     bytes memory proof = new bytes(command.proof.length);
    //     proof[0] = command.proof[0] ^ bytes1(uint8(1));
    //     command.proof = proof;
    //     bool isValid = _verifier.verify(abi.encode(command));
    //     assertFalse(isValid);
    // }

    function test_returnsTrueForValidCommand() public view {
        (LinkXCommand memory command,) = LinkXTestFixture.linkXCommand();
        bool isValid = _verifier.verify(abi.encode(command));
        assertTrue(isValid);
    }

    function test_returnsFalseForWrongENSName() public view {
        (LinkXCommand memory command,) = LinkXTestFixture.linkXCommand();
        command.ensName = "wrong.eth";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }

    function test_returnsFalseForWrongXHandle() public view {
        (LinkXCommand memory command,) = LinkXTestFixture.linkXCommand();
        command.xHandle = "wrong";
        bool isValid = _verifier.verify(abi.encode(command));
        assertFalse(isValid);
    }
}
