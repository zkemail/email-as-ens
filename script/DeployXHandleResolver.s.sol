/// NOTE: this script is not used for production, it is only used for testing
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { XHandleResolver } from "../src/XHandleResolver.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployXHandleResolverScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        XHandleResolver implementation = new XHandleResolver();
        console.log("Implementation deployed at:", address(implementation));

        // Encode the initializer function call
        bytes memory initData = abi.encodeWithSelector(XHandleResolver.initialize.selector);

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        vm.stopBroadcast();

        console.log("\nX_HANDLE_RESOLVER=", address(proxy));
        console.log("X_HANDLE_RESOLVER_IMPLEMENTATION=", address(implementation));
    }
}
