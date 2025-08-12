// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { EmailAuthVerifier, DecodedFields } from "../../../../src/verifiers/EmailAuthVerifier.sol";

contract EmailAuthVerifierHelper is EmailAuthVerifier {
    constructor() EmailAuthVerifier(address(0), address(0)) { }

    function encode(uint256[] calldata, bytes calldata) external pure override returns (bytes memory) {
        return "";
    }

    function verify(bytes memory) external pure override returns (bool) {
        return false;
    }

    function packPubSignals(DecodedFields memory decodedFields) public pure returns (uint256[60] memory) {
        return _packPubSignals(decodedFields);
    }
}
