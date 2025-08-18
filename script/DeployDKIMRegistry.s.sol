// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { UserOverrideableDKIMRegistry } from "@zk-email/contracts/UserOverrideableDKIMRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployDKIMRegistryScript is Script {
    address internal constant _ICP_ORACLE_SIGNER = 0x024828b9075e3A315Cea29a6Ccc7a2bEd6DDDC53; // chain agnostic

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        UserOverrideableDKIMRegistry dkimRegistry = new UserOverrideableDKIMRegistry();

        bytes memory initData =
            abi.encodeWithSelector(UserOverrideableDKIMRegistry.initialize.selector, deployer, _ICP_ORACLE_SIGNER, 0);

        ERC1967Proxy proxy = new ERC1967Proxy(address(dkimRegistry), initData);

        vm.stopBroadcast();

        console.log("DKIM_REGISTRY_PROXY=", address(proxy));
    }
}
