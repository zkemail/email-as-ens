// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { XHandleRegistrar } from "../src/XHandleRegistrar.sol";
import { XHandleResolver } from "../src/XHandleResolver.sol";
import { ClaimXHandleCommandVerifier } from "../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { HonkVerifier } from "../test/fixtures/handleCommand/HonkVerifier.sol";
import { EnsUtils } from "../src/utils/EnsUtils.sol";

contract DeployAllScript is Script {
    using EnsUtils for bytes;

    // Sepolia always valid DKIM registry
    address public constant DKIM_REGISTRY = 0xc4f628496b8c474096650C8f9023954643cC614F;

    // Root ENS node for x.zkemail.eth
    // This is namehash("x.zkemail.eth")
    bytes32 public constant ROOT_NODE = 0xbebbd33c5fc468150ee72842a5ea444454559a966146ac10ffeecabf0e8ee622;

    // Existing resolver proxy on Sepolia
    address public constant RESOLVER_PROXY = 0xa217F713FB7873d39cb2ef43dAc29Da445c92cB9;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n=== Step 1: Deploy XHandleRegistrar ===");

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

        console.log("\n=== Step 2: Upgrade XHandleResolver ===");

        // Deploy new resolver implementation
        XHandleResolver newResolverImpl = new XHandleResolver();
        console.log("New XHandleResolver implementation deployed at:", address(newResolverImpl));

        // Upgrade the resolver proxy
        XHandleResolver resolver = XHandleResolver(RESOLVER_PROXY);
        resolver.upgradeToAndCall(address(newResolverImpl), "");
        console.log("Resolver upgraded successfully!");

        // Set the registrar on the resolver
        resolver.setRegistrar(address(registrar));
        console.log("Registrar set on resolver!");

        vm.stopBroadcast();

        console.log("\n=== Deployment Complete ===");
        console.log("X_HANDLE_REGISTRAR=", address(registrar));
        console.log("X_HANDLE_RESOLVER=", RESOLVER_PROXY);
        console.log("X_HANDLE_RESOLVER_NEW_IMPL=", address(newResolverImpl));
        console.log("CLAIM_X_HANDLE_VERIFIER=", address(commandVerifier));
        console.log("HONK_VERIFIER=", address(honkVerifier));
        console.log("DKIM_REGISTRY=", DKIM_REGISTRY);
        console.log("ROOT_NODE (x.zkemail.eth)=", vm.toString(ROOT_NODE));

        console.log("\n=== Verification Commands ===");
        console.log("forge verify-contract", address(registrar), "src/XHandleRegistrar.sol:XHandleRegistrar");
        console.log(
            "  --constructor-args $(cast abi-encode 'constructor(address,bytes32)'",
            address(commandVerifier),
            vm.toString(ROOT_NODE),
            ")"
        );
        console.log("\nforge verify-contract", address(newResolverImpl), "src/XHandleResolver.sol:XHandleResolver");
    }
}

