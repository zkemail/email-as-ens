// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleCommandVerifier, PublicInputs } from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";

contract LinkXHandleCommandVerifierHelper is LinkXHandleCommandVerifier {
    constructor() LinkXHandleCommandVerifier(address(0), address(0)) { }

    function packPublicInputs(PublicInputs memory publicInputs) public pure returns (bytes32[] memory fields) {
        return _packPublicInputs(publicInputs);
    }
}
