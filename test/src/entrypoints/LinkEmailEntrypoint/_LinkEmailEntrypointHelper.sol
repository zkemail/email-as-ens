// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkEmailEntrypoint } from "../../../../src/entrypoints/LinkEmailEntrypoint.sol";

contract LinkEmailEntrypointHelper is LinkEmailEntrypoint {
    constructor(address verifier) LinkEmailEntrypoint(verifier) { }

    function isUsed(bytes32 nullifier) public view returns (bool) {
        return _isUsed[nullifier];
    }
}
