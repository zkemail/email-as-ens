// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { ZkEmailRegistrar } from "../src/ZkEmailRegistrar.sol";
import { ProveAndClaimCommandVerifier } from "../src/utils/ProveAndClaimCommandVerifier.sol";
import { Groth16Verifier } from "../test/fixtures/Groth16Verifier.sol";

contract ZkEmailRegistrarScript is Script {
    address public constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    // namehash(zkemail.eth)
    bytes32 public constant DEFAULT_ROOT_NODE = 0x9779bbcebf3daee4340657d5ad76d6cc4289ba3185d61166d7b7099ae8bab0b8;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        ProveAndClaimCommandVerifier verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));
        ZkEmailRegistrar registrar = new ZkEmailRegistrar(DEFAULT_ROOT_NODE, address(verifier), ENS_REGISTRY);
        vm.stopBroadcast();

        console.log("ZK_EMAIL_REGISTRAR=", address(registrar));
    }
}
