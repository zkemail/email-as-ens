// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { HandleResolver } from "../src/resolvers/HandleResolver.sol";

contract UpgradeHandleResolverScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get addresses from environment or use defaults
        address proxyAddress = vm.envOr("X_HANDLE_RESOLVER", 0xa217F713FB7873d39cb2ef43dAc29Da445c92cB9);
        address registrarAddress = vm.envOr("X_HANDLE_REGISTRAR", address(0));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        HandleResolver newImplementation = new HandleResolver();
        console.log("New implementation deployed at:", address(newImplementation));

        // Upgrade proxy to new implementation
        HandleResolver proxy = HandleResolver(proxyAddress);
        proxy.upgradeToAndCall(address(newImplementation), "");
        console.log("Proxy upgraded successfully!");

        // Set registrar if provided
        if (registrarAddress != address(0)) {
            proxy.setRegistrar(registrarAddress);
            console.log("Registrar set to:", registrarAddress);
        } else {
            console.log("WARNING: No registrar address provided, skipping setRegistrar");
        }

        vm.stopBroadcast();

        console.log("\n=== Upgrade Summary ===");
        console.log("Proxy address:", proxyAddress);
        console.log("New implementation:", address(newImplementation));
        console.log("Registrar:", registrarAddress);
    }
}

