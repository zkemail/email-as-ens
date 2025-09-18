// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXHandleCommandVerifier, PubSignals } from "../../../../src/verifiers/LinkXHandleCommandVerifier.sol";

contract LinkXHandleCommandVerifierHelper is LinkXHandleCommandVerifier {
    constructor() LinkXHandleCommandVerifier(address(0), address(0)) { }

    function packPubSignals(PubSignals memory decodedFields) public pure returns (bytes32[] memory pubSignals) {
        return _packPubSignals(decodedFields);
    }
}
