// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkEmailVerifier } from "../../../src/LinkEmailVerifier.sol";

contract LinkEmailVerifierHelper is LinkEmailVerifier {
    constructor(address verifier) LinkEmailVerifier(verifier) { }

    function isUsed(bytes32 nullifier) public view returns (bool) {
        return _isUsed[nullifier];
    }
}
