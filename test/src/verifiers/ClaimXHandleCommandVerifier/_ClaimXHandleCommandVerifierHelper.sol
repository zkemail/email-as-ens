// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ClaimXHandleCommandVerifier, PublicInputs } from "../../../../src/verifiers/ClaimXHandleCommandVerifier.sol";

contract ClaimXHandleCommandVerifierHelper is ClaimXHandleCommandVerifier {
    constructor(address honkVerifier, address dkimRegistry) ClaimXHandleCommandVerifier(honkVerifier, dkimRegistry) { }

    function packPublicInputs(PublicInputs memory publicInputs) public pure returns (bytes32[] memory fields) {
        return _packPublicInputs(publicInputs);
    }
}
