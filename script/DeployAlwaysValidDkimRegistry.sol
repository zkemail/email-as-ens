// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { AlwaysValidDKIMRegistry } from "../test/fixtures/AlwaysValidDKIMRegistry.sol";

contract DeployAlwaysValidDkimRegistryScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        IDKIMRegistry dkimRegistry = new AlwaysValidDKIMRegistry();
        vm.stopBroadcast();

        console.log("DKIM_REGISTRY=", address(dkimRegistry));
    }
}
