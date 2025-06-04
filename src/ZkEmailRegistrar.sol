// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";

contract ZkEmailRegistrar {
    using Bytes for bytes;

    function _nameHash(bytes memory nameBytes, uint256 offset) internal pure returns (bytes32) {
        uint256 len = nameBytes.length;

        if (offset >= len) {
            return bytes32(0);
        }

        uint256 labelEnd = _findLabelEnd(nameBytes, offset);
        bytes memory label = nameBytes.slice(offset, labelEnd);
        bytes32 labelHash = keccak256(label);

        // Recursive case: hash of (parent nameHash + current labelHash)
        return keccak256(abi.encodePacked(_nameHash(nameBytes, labelEnd + 1), labelHash));
    }

    // return the position of the first dot or the end of the string
    function _findLabelEnd(bytes memory nameBytes, uint256 offset) internal pure returns (uint256) {
        uint256 len = nameBytes.length;

        for (uint256 i = offset; i < len; i++) {
            if (nameBytes[i] == 0x2E) {
                // ASCII '.'
                return i;
            }
        }

        return len; // No dot found, return end of string
    }
}
