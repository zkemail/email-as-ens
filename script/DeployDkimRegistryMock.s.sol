// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { DKIMRegistryMock } from "../test/fixtures/DKIMRegistryMock.sol";

contract DeployDKIMRegistryMockScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        IDKIMRegistry dkimRegistry = new DKIMRegistryMock();
        vm.stopBroadcast();

        console.log("DKIM_REGISTRY=", address(dkimRegistry));
    }
}
