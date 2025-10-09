// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleEntrypoint } from "../../../../src/entrypoints/LinkXHandleEntrypoint.sol";

contract LinkXHandleEntrypointHelper is LinkXHandleEntrypoint {
    constructor(address verifier) LinkXHandleEntrypoint(verifier) { }

    function isUsed(bytes32 nullifier) public view returns (bool) {
        return _isUsed[nullifier];
    }
}
