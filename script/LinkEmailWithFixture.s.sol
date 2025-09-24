// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { LinkEmailVerifier } from "../src/LinkEmailVerifier.sol";
import { LinkEmailCommand } from "../src/verifiers/LinkEmailCommandVerifier.sol";
import { TestFixtures } from "../test/fixtures/TestFixtures.sol";

contract LinkEmailWithFixtureScript is Script {
    // sepolia
    address public constant LINK_EMAIL_VERIFIER = 0x1e6786bCB1848d801c26b115af0f4c23F08B442c;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        LinkEmailVerifier verifier = LinkEmailVerifier(LINK_EMAIL_VERIFIER);
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();

        vm.startBroadcast(deployerPrivateKey);
        verifier.entrypoint(abi.encode(command));
        vm.stopBroadcast();
    }
}
