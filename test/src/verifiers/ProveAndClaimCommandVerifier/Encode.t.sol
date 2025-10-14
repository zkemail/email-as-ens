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
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        address dkimRegistry = _createMockDkimRegistry(
            command.emailAuthProof.publicInputs.domainName, command.emailAuthProof.publicInputs.publicKeyHash
        );
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()), dkimRegistry);
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (ProveAndClaimCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.claimEnsCommand();

        bytes memory encodedData = _verifier.encode(command.emailAuthProof.proof, expectedPublicInputs);
        ProveAndClaimCommand memory decodedCommand = abi.decode(encodedData, (ProveAndClaimCommand));

        assertEq(decodedCommand.resolver, command.resolver);
        assertEq(decodedCommand.owner, command.owner);
        for (uint256 i = 0; i < decodedCommand.emailParts.length; i++) {
            assertEq(decodedCommand.emailParts[i], command.emailParts[i]);
        }
        _assertPublicInputsEq(decodedCommand.emailAuthProof.publicInputs, command.emailAuthProof.publicInputs);
    }
}
