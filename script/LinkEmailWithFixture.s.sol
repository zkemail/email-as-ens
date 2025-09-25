// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script } from "forge-std/Script.sol";
import { LinkEmailVerifier } from "../src/LinkEmailVerifier.sol";
import { LinkEmailCommand } from "../src/verifiers/LinkEmailCommandVerifier.sol";
import { DKIMRegistryMock } from "../test/fixtures/DKIMRegistryMock.sol";
import { TestFixtures } from "../test/fixtures/TestFixtures.sol";

contract LinkEmailWithFixtureScript is Script {
    // sepolia mock
    address public constant DKIM_REGISTRY = 0xec22Ad55d5D26F1DAB8D020FEBb423C03f535D40;
    // sepolia
    address public constant LINK_EMAIL_VERIFIER = 0x5B32859B0294fcaD4Ca13e1b0C5105d2e8cEa096;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        LinkEmailVerifier verifier = LinkEmailVerifier(LINK_EMAIL_VERIFIER);
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        bytes32 domainHash = keccak256(bytes(command.emailAuthProof.publicInputs.domainName));

        vm.startBroadcast(deployerPrivateKey);

        DKIMRegistryMock(DKIM_REGISTRY).setValid(domainHash, command.emailAuthProof.publicInputs.publicKeyHash, true);
        verifier.entrypoint(abi.encode(command));

        vm.stopBroadcast();
    }
}
