// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "../../src/utils/Verifier.sol";

interface IVerifier {
    function isValid(ProveAndClaimCommand calldata command) external view returns (bool);
}

contract ProveAndClaimProofEncoder {
    address public immutable VERIFIER;

    constructor(address verifier) {
        VERIFIER = verifier;
    }

    function encode(uint256[] calldata publicSignals) public pure returns (bytes memory command) { }

    function verify(bytes calldata command) public view returns (bool) {
        ProveAndClaimCommand memory command = abi.decode(command, (ProveAndClaimCommand));
        return IVerifier(VERIFIER).isValid(command);
    }
}
