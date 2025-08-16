// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { LinkEmailVerifier } from "../src/LinkEmailVerifier.sol";
import { LinkEmailCommandVerifier } from "../src/verifiers/LinkEmailCommandVerifier.sol";
import { Groth16Verifier } from "../test/fixtures/Groth16Verifier.sol";

contract LinkEmailVerifierScript is Script {
    address internal constant _ICP_ORACLE_SIGNER = 0x024828b9075e3A315Cea29a6Ccc7a2bEd6DDDC53; // chain agnostic

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        LinkEmailCommandVerifier commandVerifier =
            new LinkEmailCommandVerifier(address(new Groth16Verifier()), _ICP_ORACLE_SIGNER);
        LinkEmailVerifier verifier = new LinkEmailVerifier(address(commandVerifier));
        vm.stopBroadcast();

        console.log("LINK_EMAIL_VERIFIER=", address(verifier));
    }
}
