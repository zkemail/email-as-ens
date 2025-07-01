// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { Groth16Verifier } from "./Groth16Verifier.sol";
import { ProveAndClaimCommandVerifier } from "../../src/utils/Verifier.sol";
import { ProveAndClaimProofEncoder } from "./Encoder.sol";
import { TestFixtures } from "./TestFixtures.sol";
import { ProveAndClaimCommand } from "../../src/utils/Verifier.sol";

contract ProveAndClaimProofEncoderTest is Test {
    Groth16Verifier public groth16Verifier;
    ProveAndClaimCommandVerifier public verifier;
    ProveAndClaimProofEncoder public encoder;

    function setUp() public {
        groth16Verifier = new Groth16Verifier();
        verifier = new ProveAndClaimCommandVerifier(address(groth16Verifier));
        encoder = new ProveAndClaimProofEncoder(address(verifier));
    }

    function testEncodeAndVerify() public {
        (ProveAndClaimCommand memory command, uint256[60] memory publicSignalsFixed) = TestFixtures.claimEnsCommand();

        uint256[] memory publicSignals = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            publicSignals[i] = publicSignalsFixed[i];
        }

        bytes memory encodedCommand = encoder.encode(publicSignals, command.proof);

        bool success = encoder.verify(encodedCommand);
        assertTrue(success, "Verification should succeed");
    }

    function testReconstructedCommand() public {
        (ProveAndClaimCommand memory originalCommand, uint256[60] memory publicSignalsFixed) =
            TestFixtures.claimEnsCommand();

        uint256[] memory publicSignals = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            publicSignals[i] = publicSignalsFixed[i];
        }

        bytes memory encodedCommandBytes = encoder.encode(publicSignals, originalCommand.proof);
        ProveAndClaimCommand memory reconstructedCommand = abi.decode(encodedCommandBytes, (ProveAndClaimCommand));

        assertEq(reconstructedCommand.domain, originalCommand.domain, "Domain mismatch");
        assertEq(reconstructedCommand.email, originalCommand.email, "Email mismatch");
        assertEq(reconstructedCommand.owner, originalCommand.owner, "Owner mismatch");
        assertEq(reconstructedCommand.dkimSignerHash, originalCommand.dkimSignerHash, "DKIM signer hash mismatch");
        assertEq(reconstructedCommand.nullifier, originalCommand.nullifier, "Nullifier mismatch");
        assertEq(reconstructedCommand.timestamp, originalCommand.timestamp, "Timestamp mismatch");
        assertEq(reconstructedCommand.accountSalt, originalCommand.accountSalt, "Account salt mismatch");
        assertEq(reconstructedCommand.isCodeEmbedded, originalCommand.isCodeEmbedded, "isCodeEmbedded flag mismatch");
        assertEq(reconstructedCommand.miscellaneousData, originalCommand.miscellaneousData, "Misc data mismatch");
        assertEq(reconstructedCommand.proof, originalCommand.proof, "Proof mismatch");

        assertEq(
            reconstructedCommand.emailParts.length, originalCommand.emailParts.length, "Email parts length mismatch"
        );
        for (uint256 i = 0; i < reconstructedCommand.emailParts.length; i++) {
            assertEq(reconstructedCommand.emailParts[i], originalCommand.emailParts[i], "Email part content mismatch");
        }
    }
}
