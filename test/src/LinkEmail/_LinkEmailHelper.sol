// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkEmail } from "../../../src/LinkEmail.sol";

contract LinkEmailHelper is LinkEmail {
    constructor(address verifier) LinkEmail(verifier) { }

    function isUsed(bytes32 nullifier) public view returns (bool) {
        return _isUsed[nullifier];
    }
}
