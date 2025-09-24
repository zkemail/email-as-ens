// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { EmailAuthVerifier, PublicInputs } from "../../../../src/verifiers/EmailAuthVerifier.sol";

contract EmailAuthVerifierHelper is EmailAuthVerifier {
    constructor() EmailAuthVerifier(address(0), address(0)) { }

    function encode(bytes calldata, bytes32[] calldata) external pure override returns (bytes memory) {
        return "";
    }

    function verify(bytes memory) external pure override returns (bool) {
        return false;
    }

    function packPublicInputs(PublicInputs memory decodedFields) public pure returns (bytes32[] memory) {
        return _packPublicInputs(decodedFields);
    }
}
