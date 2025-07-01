// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { Groth16Verifier } from "./Groth16Verifier.sol";
import { ProveAndClaimCommandVerifier } from "../../src/utils/Verifier.sol";
import { ProveAndClaimProofEncoder } from "./Encoder.sol";

contract DeployEncoder is Script {
    function run() external returns (ProveAndClaimProofEncoder, ProveAndClaimCommandVerifier, Groth16Verifier) {
        vm.startBroadcast();

        Groth16Verifier groth16Verifier = new Groth16Verifier();
        ProveAndClaimCommandVerifier verifier = new ProveAndClaimCommandVerifier(address(groth16Verifier));
        ProveAndClaimProofEncoder encoder = new ProveAndClaimProofEncoder(address(verifier));

        vm.stopBroadcast();

        return (encoder, verifier, groth16Verifier);
    }
}
