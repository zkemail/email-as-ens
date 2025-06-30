// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title StringUtils
 * @notice Provides utility functions for string manipulation.
 */
library StringUtils {
    /**
     * @notice Converts a uint256 field value to an ASCII string, mirroring a specific Python implementation.
     * @dev The conversion process is as follows:
     *      1. The uint256 is treated as a 32-byte array (big-endian).
     *      2. Leading zero bytes of the uint256 are ignored (as Python's hex() does).
     *      3. Any trailing null bytes (`\x00`) from the resulting bytes are removed, simulating `rstrip('\x00')`.
     *      4. The remaining byte sequence is reversed.
     *      5. The reversed bytes are converted to an ASCII string.
     *      This is equivalent to the following Python code from the test fixtures:
     *      ```python
     *      def field_to_ascii(field_value):
     *          hex_str = hex(field_value)[2:]
     *          if len(hex_str) % 2:
     *              hex_str = '0' + hex_str
     *          bytes_data = bytes.fromhex(hex_str)
     *          return bytes_data.decode('ascii').rstrip('\x00')[::-1]  # reverse
     *      ```
     * @param field The uint256 value to convert.
     * @return The resulting ASCII string.
     */
    function fieldToAscii(uint256 field) internal pure returns (string memory) {
        if (field == 0) {
            return "";
        }

        bytes32 fieldBytes = bytes32(field);

        uint256 startIndex = 0;
        while (startIndex < 32 && fieldBytes[startIndex] == 0) {
            startIndex++;
        }

        uint256 len = 32 - startIndex;
        bytes memory tempBytes = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            tempBytes[i] = fieldBytes[startIndex + i];
        }

        uint256 trimmedLen = len;
        while (trimmedLen > 0 && tempBytes[trimmedLen - 1] == 0) {
            trimmedLen--;
        }

        if (trimmedLen == 0) {
            return "";
        }

        bytes memory reversedBytes = new bytes(trimmedLen);
        for (uint256 i = 0; i < trimmedLen; i++) {
            reversedBytes[i] = tempBytes[trimmedLen - 1 - i];
        }

        return string(reversedBytes);
    }

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
    function bytesToFields(bytes memory _bytes, uint256 _paddedSize) internal pure returns (uint256[] memory) {
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
     * @notice Converts an array of field elements back into a byte array.
     * @param fields The array of uint256 field elements.
     * @param originalSize The original size of the byte array before padding and packing.
     * @return The reconstructed byte array.
     * @dev This function is the reverse of `bytesToFields`. It unpacks field elements,
     *      each containing up to 31 bytes, and reconstructs the original byte array.
     *      The `originalSize` parameter is crucial to correctly handle padding and avoid
     *      including extra zero bytes that might have been added during packing.
     */
    function fieldsToBytes(uint256[] memory fields, uint256 originalSize) internal pure returns (bytes memory) {
        bytes memory result = new bytes(originalSize);
        uint256 byteIndex = 0;
        for (uint256 i = 0; i < fields.length; i++) {
            uint256 field = fields[i];
            for (uint256 j = 0; j < 31; j++) {
                if (byteIndex < originalSize) {
                    result[byteIndex] = bytes1(uint8(field & 0xFF));
                    field >>= 8;
                    byteIndex++;
                } else {
                    break;
                }
            }
        }
        return result;
    }
}
