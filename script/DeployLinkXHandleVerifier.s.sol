// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { LinkXHandleVerifier } from "../src/LinkXHandleVerifier.sol";
import { LinkXHandleCommandVerifier } from "../src/verifiers/LinkXHandleCommandVerifier.sol";
import { HonkVerifier } from "../test/fixtures/linkXHandleCommand/circuit/target/HonkVerifier.sol";

contract DeployLinkXHandleVerifierScript is Script {
    // sepolia
    // address public constant DKIM_REGISTRY = 0xe24c24Ab94c93D5754De1cbE61b777e47cc57723;
    // sepolia always valid dkim registry
    address public constant DKIM_REGISTRY = 0xc4f628496b8c474096650C8f9023954643cC614F;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        LinkXHandleCommandVerifier commandVerifier =
            new LinkXHandleCommandVerifier(address(new HonkVerifier()), DKIM_REGISTRY);
        LinkXHandleVerifier verifier = new LinkXHandleVerifier(address(commandVerifier));
        vm.stopBroadcast();

        console.log("LINK_X_HANDLE_VERIFIER=", address(verifier));
    }
}
