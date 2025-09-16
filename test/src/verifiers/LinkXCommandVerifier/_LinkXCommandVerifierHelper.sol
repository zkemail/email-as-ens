// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkXCommandVerifier, PubSignals } from "../../../../src/verifiers/LinkXCommandVerifier.sol";

contract LinkXCommandVerifierHelper is LinkXCommandVerifier {
    constructor() LinkXCommandVerifier(address(0)) { }

    function packPubSignals(PubSignals memory decodedFields) public pure returns (bytes32[] memory pubSignals) {
        return _packPubSignals(decodedFields);
    }
}
