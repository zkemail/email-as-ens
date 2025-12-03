// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkHandleCommandVerifier, PublicInputs } from "../../../../src/verifiers/LinkHandleCommandVerifier.sol";

contract LinkHandleCommandVerifierHelper is LinkHandleCommandVerifier {
    constructor(address honkVerifier, address dkimRegistry) LinkHandleCommandVerifier(honkVerifier, dkimRegistry) { }

    function packPublicInputs(PublicInputs memory publicInputs) public pure returns (bytes32[] memory fields) {
        return _packPublicInputs(publicInputs);
    }
}
