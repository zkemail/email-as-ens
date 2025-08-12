// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { LinkEmailVerifier } from "../src/LinkEmailVerifier.sol";
import { LinkEmailCommandVerifier } from "../src/verifiers/LinkEmailCommandVerifier.sol";
import { Groth16Verifier } from "../test/fixtures/Groth16Verifier.sol";

contract LinkEmailVerifierScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        // TODO: replace address(0) with a real DKIM registry when deploying
        LinkEmailCommandVerifier commandVerifier =
            new LinkEmailCommandVerifier(address(new Groth16Verifier()), address(0));
        LinkEmailVerifier verifier = new LinkEmailVerifier(address(commandVerifier));
        vm.stopBroadcast();

        console.log("LINK_EMAIL_VERIFIER=", address(verifier));
    }
}
