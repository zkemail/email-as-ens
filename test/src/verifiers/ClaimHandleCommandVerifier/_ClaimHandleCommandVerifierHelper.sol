// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ClaimHandleCommandVerifier, PublicInputs } from "../../../../src/verifiers/ClaimHandleCommandVerifier.sol";

contract ClaimHandleCommandVerifierHelper is ClaimHandleCommandVerifier {
    constructor(address honkVerifier, address dkimRegistry) ClaimHandleCommandVerifier(honkVerifier, dkimRegistry) { }

    function packPublicInputs(PublicInputs memory publicInputs) public pure returns (bytes32[] memory fields) {
        return _packPublicInputs(publicInputs);
    }
}
