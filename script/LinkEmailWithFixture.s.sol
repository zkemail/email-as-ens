// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { LinkEmailEntrypoint } from "../src/entrypoints/LinkEmailEntrypoint.sol";
import { LinkEmailCommand } from "../src/verifiers/LinkEmailCommandVerifier.sol";
import { TestFixtures } from "../test/fixtures/TestFixtures.sol";

contract LinkEmailWithFixtureScript is Script {
    // sepolia mock
    address public constant DKIM_REGISTRY = 0xec22Ad55d5D26F1DAB8D020FEBb423C03f535D40;
    // sepolia
    address public constant LINK_EMAIL_VERIFIER = 0x64da043037E77971C9Cea2C49a54F8A5872B8f1A;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        LinkEmailEntrypoint verifier = LinkEmailEntrypoint(LINK_EMAIL_VERIFIER);
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();

        vm.startBroadcast(deployerPrivateKey);

        bytes memory encodedCommand = verifier.encode(command.emailAuthProof.proof, expectedPublicInputs);
        verifier.entrypoint(encodedCommand);

        vm.stopBroadcast();
    }
}
