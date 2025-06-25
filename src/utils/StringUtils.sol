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
}
