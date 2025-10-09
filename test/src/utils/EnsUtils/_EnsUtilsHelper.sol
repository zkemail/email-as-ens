// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { EnsUtils } from "src/utils/EnsUtils.sol";

contract EnsUtilsHelper {
    function callNamehash(bytes memory name) external pure returns (bytes32) {
        return EnsUtils.namehash(name);
    }

    function callNamehashWithOffset(bytes memory name, uint256 offset) external pure returns (bytes32) {
        return EnsUtils.namehash(name, offset);
    }

    function callPackHeaderHash(bytes32 headerHash) external pure returns (bytes32[] memory) {
        return EnsUtils.packHeaderHash(headerHash);
    }

    function callUnpackHeaderHash(bytes32[] memory fields) external pure returns (bytes32) {
        return EnsUtils.unpackHeaderHash(fields);
    }

    function callPackPubKey(bytes memory pubKeyBytes) external pure returns (bytes32[] memory fields) {
        return EnsUtils.packPubKey(pubKeyBytes);
    }

    function callUnpackPubKey(
        bytes32[] calldata publicInputs,
        uint256 startIndex
    )
        external
        pure
        returns (bytes memory pubKeyBytes)
    {
        return EnsUtils.unpackPubKey(publicInputs, startIndex);
    }

    function callExtractEmailParts(string memory email) external pure returns (string[] memory) {
        return EnsUtils.extractEmailParts(email);
    }

    function callVerifyEmailParts(string[] memory emailParts, string memory email) external pure returns (bool) {
        return EnsUtils.verifyEmailParts(emailParts, email);
    }
}
