// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { ECDSAOwnedDKIMRegistry } from "@zk-email/contracts/ECDSAOwnedDKIMRegistry.sol";

contract DeployDKIMRegistryScript is Script {
    address internal constant _ICP_ORACLE_SIGNER = 0x6293A80BF4Bd3fff995a0CAb74CBf281d922dA02; // chain agnostic

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        ECDSAOwnedDKIMRegistry dkimRegistry = new ECDSAOwnedDKIMRegistry(_ICP_ORACLE_SIGNER);
        vm.stopBroadcast();

        console.log("DKIM_REGISTRY=", address(dkimRegistry));
    }
}
