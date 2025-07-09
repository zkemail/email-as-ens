// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";

/**
 * @title CircuitUtils
 * @notice Library for ZK circuit-related utilities including field element packing and proof processing
 * @dev This library provides functions for converting between byte arrays and field elements
 *      and other utilities needed for zero-knowledge proof circuit compatibility.
 */
library CircuitUtils {
    using Bytes for bytes;

    /**
     * @notice Packs byte arrays into field elements for ZK circuit compatibility
     * @param _bytes The byte array to pack into field elements
     * @param _paddedSize The target size after padding (must be larger than or equal to _bytes.length)
     * @return An array of field elements containing the packed byte data
     * @dev This function packs bytes into field elements by:
     *      1. Determining how many field elements are needed (31 bytes per field element)
     *      2. Packing bytes in little-endian order within each field element
     *      3. Padding with zeros if the input is shorter than _paddedSize
     *      4. Ensuring the resulting field elements are compatible with ZK circuits
     *
     *      Each field element can contain up to 31 bytes to ensure the result stays below
     *      the BN128 curve order. Bytes are packed as: byte0 + (byte1 << 8) + (byte2 << 16) + ...
     */
    function packBytes2Fields(bytes memory _bytes, uint256 _paddedSize) internal pure returns (uint256[] memory) {
        uint256 remain = _paddedSize % 31;
        uint256 numFields = (_paddedSize - remain) / 31;
        if (remain > 0) {
            numFields += 1;
        }
        uint256[] memory fields = new uint256[](numFields);
        uint256 idx = 0;
        uint256 byteVal = 0;
        for (uint256 i = 0; i < numFields; i++) {
            for (uint256 j = 0; j < 31; j++) {
                idx = i * 31 + j;
                if (idx >= _paddedSize) {
                    break;
                }
                if (idx >= _bytes.length) {
                    byteVal = 0;
                } else {
                    byteVal = uint256(uint8(_bytes[idx]));
                }
                if (j == 0) {
                    fields[i] = byteVal;
                } else {
                    fields[i] += (byteVal << (8 * j));
                }
            }
        }
        return fields;
    }

    /**
     * @notice Unpacks field elements back to bytes
     * @param publicSignals Array of public signals
     * @param startIndex Starting index in publicSignals
     * @param numFields Number of fields to unpack
     * @param paddedSize Original padded size of the bytes
     * @return The unpacked bytes
     */
    function unpackFields2Bytes(
        uint256[] calldata publicSignals,
        uint256 startIndex,
        uint256 numFields,
        uint256 paddedSize
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(paddedSize);
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < numFields; i++) {
            uint256 field = publicSignals[startIndex + i];
            for (uint256 j = 0; j < 31 && resultIndex < paddedSize; j++) {
                result[resultIndex] = bytes1(uint8(field & 0xFF));
                field = field >> 8;
                resultIndex++;
            }
        }

        // Trim trailing zeros
        uint256 actualLength = 0;
        for (uint256 i = 0; i < result.length; i++) {
            if (result[i] != 0) {
                actualLength = i + 1;
            }
        }

        return result.slice(0, actualLength);
    }
}
