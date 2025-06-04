// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { ZkEmailRegistrar } from "../src/ZkEmailRegistrar.sol";
import { TestFixtures } from "../test/fixtures/TestFixtures.sol";
import { ProveAndClaimCommand } from "../src/utils/Verifier.sol";

/**
 * @title ClaimWithFixtureCommand Script
 * @notice Script to claim an ENS name using the sample fixture command
 * @dev This script uses the test fixture command to demonstrate claiming functionality
 *      with the deployed ZkEmailRegistrar contract
 */
contract ClaimWithFixtureCommandScript is Script {
    address public constant PUBLIC_RESOLVER = 0x8948458626811dd0c23EB25Cc74291247077cC51;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address zkEmailRegistrarAddress = vm.envAddress("ZK_EMAIL_REGISTRAR");

        console.log("=== Claiming with Fixture Command ===");
        console.log("ZkEmailRegistrar address:", zkEmailRegistrarAddress);

        // Get the sample fixture command
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();

        vm.startBroadcast(deployerPrivateKey);

        // Get the registrar contract instance
        ZkEmailRegistrar registrar = ZkEmailRegistrar(zkEmailRegistrarAddress);

        console.log("Calling proveAndClaim...");

        try registrar.proveAndClaim(command) {
            console.log("Successfully claimed ENS name!");
            bytes32 node = 0xb543dfbad6a1819b3c971e07534acd306294f23b7441d27154569c8fe3c11899;
            try registrar.setRecord(node, command.owner, PUBLIC_RESOLVER, 0) {
                console.log("Successfully set record!");
            } catch Error(string memory reason) {
                console.log("Set record failed with reason:", reason);
            } catch {
                console.log("Set record failed with unknown error");
            }
        } catch Error(string memory reason) {
            console.log("Claim failed with reason:", reason);
        } catch {
            console.log("Claim failed with unknown error");
        }

        vm.stopBroadcast();

        console.log("=== Claim Script Complete ===");
    }
}
