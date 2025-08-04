// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { LinkEmailVerifier } from "../src/LinkEmailVerifier.sol";
import { LinkEmailCommand } from "../src/verifiers/LinkEmailCommandVerifier.sol";
import { TestFixtures } from "../test/fixtures/TestFixtures.sol";

contract LinkWithFixtureScript is Script {
    address public constant LINK_EMAIL_VERIFIER = 0xe902Bc5bcc1dc15dbDF27FfE346c31c4F8FD37DF; // link email verifier
        // sepolia

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        LinkEmailVerifier verifier = LinkEmailVerifier(LINK_EMAIL_VERIFIER);
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();

        vm.startBroadcast(deployerPrivateKey);
        verifier.entrypoint(abi.encode(command));
        vm.stopBroadcast();
    }
}
