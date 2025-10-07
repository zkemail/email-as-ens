// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleVerifier } from "../../../src/LinkXHandleVerifier.sol";

contract LinkXHandleVerifierHelper is LinkXHandleVerifier {
    constructor(address verifier) LinkXHandleVerifier(verifier) { }

    function isUsed(bytes32 nullifier) public view returns (bool) {
        return _isUsed[nullifier];
    }
}
