// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { XHandleResolver } from "../src/XHandleResolver.sol";

contract UpgradeXHandleResolverScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = 0xa217F713FB7873d39cb2ef43dAc29Da445c92cB9; // vm.envAddress("X_HANDLE_RESOLVER");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        XHandleResolver newImplementation = new XHandleResolver();
        console.log("New implementation deployed at:", address(newImplementation));

        // Upgrade proxy to new implementation
        XHandleResolver proxy = XHandleResolver(proxyAddress);
        proxy.upgradeToAndCall(address(newImplementation), "");

        vm.stopBroadcast();

        console.log("\nProxy upgraded successfully!");
        console.log("Proxy address:", proxyAddress);
        console.log("New implementation:", address(newImplementation));
    }
}

