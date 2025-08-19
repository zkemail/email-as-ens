// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { ECDSAOwnedDKIMRegistry } from "@zk-email/email-tx-builder/src/utils/ECDSAOwnedDKIMRegistry.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployDKIMRegistryScript is Script {
    address internal constant _ICP_ORACLE_SIGNER = 0x6293A80BF4Bd3fff995a0CAb74CBf281d922dA02; // chain agnostic

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        ECDSAOwnedDKIMRegistry dkimRegistry = new ECDSAOwnedDKIMRegistry();

        bytes memory initData =
            abi.encodeWithSelector(ECDSAOwnedDKIMRegistry.initialize.selector, deployer, _ICP_ORACLE_SIGNER);

        ERC1967Proxy proxy = new ERC1967Proxy(address(dkimRegistry), initData);

        vm.stopBroadcast();

        console.log("DKIM_REGISTRY_PROXY=", address(proxy));
    }
}
