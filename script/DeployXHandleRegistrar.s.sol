// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { XHandleRegistrar } from "../src/XHandleRegistrar.sol";
import { ClaimXHandleCommandVerifier } from "../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { HonkVerifier } from "../test/fixtures/handleCommand/HonkVerifier.sol";
import { EnsUtils } from "../src/utils/EnsUtils.sol";

contract DeployXHandleRegistrarScript is Script {
    using EnsUtils for bytes;

    // Sepolia always valid DKIM registry
    address public constant DKIM_REGISTRY = 0xc4f628496b8c474096650C8f9023954643cC614F;

    // Root ENS node for x.zkemail.eth
    // This is namehash("x.zkemail.eth")
    bytes32 public constant ROOT_NODE = 0x5e0012104ded92db7997f91d274a016bb7ae7c0060885c14035e7125a8a7a541;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the HonkVerifier
        HonkVerifier honkVerifier = new HonkVerifier();
        console.log("HonkVerifier deployed at:", address(honkVerifier));

        // Deploy ClaimXHandleCommandVerifier
        ClaimXHandleCommandVerifier commandVerifier =
            new ClaimXHandleCommandVerifier(address(honkVerifier), DKIM_REGISTRY);
        console.log("ClaimXHandleCommandVerifier deployed at:", address(commandVerifier));

        // Deploy XHandleRegistrar
        XHandleRegistrar registrar = new XHandleRegistrar(address(commandVerifier), ROOT_NODE);
        console.log("XHandleRegistrar deployed at:", address(registrar));

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("X_HANDLE_REGISTRAR=", address(registrar));
        console.log("CLAIM_X_HANDLE_VERIFIER=", address(commandVerifier));
        console.log("HONK_VERIFIER=", address(honkVerifier));
        console.log("DKIM_REGISTRY=", DKIM_REGISTRY);
        console.log("ROOT_NODE (x.zkemail.eth)=", vm.toString(ROOT_NODE));
    }
}

