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
    address public constant LINK_EMAIL_VERIFIER = 0x64da043037E77971C9Cea2C49a54F8A5872B8f1A;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        LinkEmailVerifier verifier = LinkEmailVerifier(LINK_EMAIL_VERIFIER);
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();
        bytes32 domainHash = keccak256(bytes(command.emailAuthProof.publicInputs.domainName));

        vm.startBroadcast(deployerPrivateKey);

        DKIMRegistryMock(DKIM_REGISTRY).setValid(domainHash, command.emailAuthProof.publicInputs.publicKeyHash, true);
        bytes memory encodedCommand = verifier.encode(command.emailAuthProof.proof, expectedPublicInputs);
        verifier.entrypoint(encodedCommand);

        vm.stopBroadcast();
    }
}
