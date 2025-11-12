// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";
import { HandleCommandTestFixture } from "../../fixtures/handleCommand/HandleCommandTestFixture.sol";
import { ClaimXHandleCommand } from "../../../src/verifiers/ClaimXHandleCommandVerifier.sol";

contract EncodeTest is XHandleRegistrarTest {
    function test_ReturnsCorrectEncodedData() public view {
        // Get public inputs from fixture
        (, bytes32[] memory publicInputs) = HandleCommandTestFixture.getClaimXFixture();

        // Encode using registrar
        bytes memory encoded = _registrar.encode(_validCommand.proof, publicInputs);

        // Decode and verify
        ClaimXHandleCommand memory decoded = abi.decode(encoded, (ClaimXHandleCommand));

        assertEq(decoded.target, _validCommand.target, "Target should match");
        assertEq(decoded.proof, _validCommand.proof, "Proof should match");
        assertEq(
            decoded.publicInputs.emailNullifier,
            _validCommand.publicInputs.emailNullifier,
            "Email nullifier should match"
        );
    }
}

