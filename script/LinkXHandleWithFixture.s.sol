// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { LinkXHandleVerifier } from "../src/LinkXHandleVerifier.sol";
import { LinkXHandleCommand } from "../src/verifiers/LinkXHandleCommandVerifier.sol";
import { LinkXHandleCommandTestFixture } from "../test/fixtures/LinkXHandleCommand/LinkXHandleCommandTestFixture.sol";

contract LinkXHandleWithFixtureScript is Script {
    // sepolia
    address public constant LINK_X_HANDLE_VERIFIER = 0x13AF3e033a33Cd96e40cd7ceeE496d25947DbfD7;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        LinkXHandleVerifier verifier = LinkXHandleVerifier(LINK_X_HANDLE_VERIFIER);
        (LinkXHandleCommand memory command,) = LinkXHandleCommandTestFixture.getFixture();

        vm.startBroadcast(deployerPrivateKey);
        verifier.entrypoint(abi.encode(command));
        vm.stopBroadcast();
    }
}
