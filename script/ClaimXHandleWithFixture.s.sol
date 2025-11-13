// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { XHandleRegistrar } from "../src/XHandleRegistrar.sol";
import { ClaimXHandleCommand } from "../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { HandleCommandTestFixture } from "../test/fixtures/handleCommand/HandleCommandTestFixture.sol";

contract ClaimXHandleWithFixtureScript is Script {
    // Deployed registrar address on Sepolia
    address public constant REGISTRAR = 0xDC7b42532e8cBdEd0C453cB16116B40298a0E0e3;

    error FundingFailed();

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Load the fixture
        (ClaimXHandleCommand memory command,) = HandleCommandTestFixture.getClaimXFixture();

        console.log("\n=== Claim X Handle With Fixture ===");
        console.log("Registrar:", REGISTRAR);
        console.log("X Handle:", command.publicInputs.xHandle);
        console.log("Target Address:", command.target);
        console.log("Sender Domain:", command.publicInputs.senderDomain);

        // Get the registrar instance
        XHandleRegistrar registrar = XHandleRegistrar(REGISTRAR);

        // Calculate ENS node and predicted address
        bytes32 ensNode = 0x5e0012104ded92db7997f91d274a016bb7ae7c0060885c14035e7125a8a7a541;
        address predictedAddress = registrar.predictAddress(ensNode);

        console.log("\n=== Address Information ===");
        console.log("ENS Node:", vm.toString(ensNode));
        console.log("Predicted Account Address:", predictedAddress);

        vm.startBroadcast(deployerPrivateKey);

        registrar.entrypoint(abi.encode(command));

        vm.stopBroadcast();

        console.log("\n=== Summary ===");
        console.log("X Handle claimed:", command.publicInputs.xHandle);
        console.log("ETH withdrawn to:", command.target);
        console.log("Nullifier:", vm.toString(command.publicInputs.emailNullifier));

        console.log("\n=== View Transaction on Block Explorer ===");
        console.log("After broadcast completes, get the transaction hash from:");
        console.log("  broadcast/ClaimXHandleWithFixture.s.sol/11155111/run-latest.json");
        console.log("");
        console.log("Or run this command to extract it:");
        console.log(
            "  cat broadcast/ClaimXHandleWithFixture.s.sol/11155111/run-latest.json | jq -r '.transactions[0].hash'"
        );
        console.log("");
        console.log("View on Sepolia Etherscan:");
        console.log("  https://sepolia.etherscan.io/tx/[TRANSACTION_HASH]");
    }
}

