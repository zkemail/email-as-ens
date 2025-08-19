// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { LinkEmailVerifier } from "../src/LinkEmailVerifier.sol";
import { LinkEmailCommandVerifier } from "../src/verifiers/LinkEmailCommandVerifier.sol";

contract LinkEmailVerifierScript is Script {
    address internal constant _DKIM_REGISTRY = 0x7A9628AEC0910018dEbb57C7fcd480A0986630aC;
    address internal constant _GROTH16_VERIFIER = 0xaaA30633cA407cD0ed6D25b8B77744842F055ED2;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        LinkEmailCommandVerifier commandVerifier = new LinkEmailCommandVerifier(_GROTH16_VERIFIER, _DKIM_REGISTRY);
        LinkEmailVerifier verifier = new LinkEmailVerifier(address(commandVerifier));
        vm.stopBroadcast();

        console.log("LINK_EMAIL_VERIFIER=", address(verifier));
    }
}
