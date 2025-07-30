// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";

library EnsUtils {
    using Bytes for bytes;

    function namehash(bytes memory name) internal pure returns (bytes32) {
        return namehash(name, 0);
    }

    function namehash(bytes memory name, uint256 offset) internal pure returns (bytes32) {
        uint256 atSignIndex = name.indexOf(0x40);
        if (atSignIndex != type(uint256).max) {
            name[atSignIndex] = bytes1("$");
        }

        uint256 len = name.length;

        if (offset >= len) {
            return bytes32(0);
        }

        uint256 labelEnd = Math.min(name.indexOf(0x2E, offset), len);
        bytes memory label = name.slice(offset, labelEnd);
        bytes32 labelHash = keccak256(label);

        // Recursive case: hash of (parent nameHash + current labelHash)
        return keccak256(abi.encodePacked(namehash(name, labelEnd + 1), labelHash));
    }
}
