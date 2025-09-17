// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { NoirUtils } from "src/utils/NoirUtils.sol";

contract NoirUtilsHelper {
    function callPackBoundedVecU8(string memory input, uint256 numFields) external pure returns (bytes32[] memory) {
        return NoirUtils.packBoundedVecU8(input, numFields);
    }

    function callUnpackBoundedVecU8(bytes32[] memory fields) external pure returns (string memory) {
        return NoirUtils.unpackBoundedVecU8(fields);
    }
}
