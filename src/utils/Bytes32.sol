// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

library Bytes32 {
    function slice(bytes32[] memory array, uint256 start, uint256 end) internal pure returns (bytes32[] memory) {
        // sanitize
        uint256 length = array.length;
        end = Math.min(end, length);
        start = Math.min(start, end);

        // allocate and copy
        uint256 n = end - start;
        bytes32[] memory result = new bytes32[](n);
        assembly ("memory-safe") {
            let src := add(add(array, 0x20), mul(start, 0x20)) // array.data + start*32
            let dst := add(result, 0x20) // result.data
            mcopy(dst, src, mul(n, 0x20)) // copy n*32 bytes
        }

        return result;
    }

    function splice(bytes32[] memory array, uint256 start, bytes32[] memory elements)
        internal
        pure
        returns (bytes32[] memory)
    {
        uint256 len = array.length;
        if (start >= len) {
            return array;
        }

        uint256 writable = Math.min(elements.length, len - start);

        assembly ("memory-safe") {
            let arrData := add(array, 0x20)
            let elData := add(elements, 0x20)
            let dst := add(arrData, mul(start, 0x20))
            mcopy(dst, elData, mul(writable, 0x20))
        }

        return array;
    }
}
