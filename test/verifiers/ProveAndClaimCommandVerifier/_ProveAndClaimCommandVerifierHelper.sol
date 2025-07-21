// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {
    ProveAndClaimCommand, ProveAndClaimCommandVerifier
} from "../../../src/verifiers/ProveAndClaimCommandVerifier.sol";

contract ProveAndClaimCommandVerifierHelper is ProveAndClaimCommandVerifier {
    constructor() ProveAndClaimCommandVerifier(address(0)) { }

    function buildPubSignals(ProveAndClaimCommand memory command) public pure returns (uint256[60] memory) {
        return _packPubSignals(command.proof.fields);
    }
}
