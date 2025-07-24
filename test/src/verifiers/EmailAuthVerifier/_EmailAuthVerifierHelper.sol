// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { EmailAuthVerifier, DecodedFields } from "../../../../src/verifiers/EmailAuthVerifier.sol";

contract EmailAuthVerifierHelper is EmailAuthVerifier {
    constructor() EmailAuthVerifier() { }

    function packPubSignals(DecodedFields memory decodedFields) public pure returns (uint256[60] memory) {
        return _packPubSignals(decodedFields);
    }
}
