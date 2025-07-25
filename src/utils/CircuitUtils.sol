// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";

/**
 * @title CircuitUtils
 * @notice Library for ZK circuit-related utilities including field element packing and proof processing
 * @dev This library provides functions for converting between byte arrays and field elements
 *      and other utilities needed for zero-knowledge proof circuit compatibility.
 */
library CircuitUtils {
    using Bytes for bytes;
    using Strings for string;

    /**
     * @notice Error thrown when the public signals array length is not exactly 60
     * @dev The ZK circuit expects exactly 60 public signals for verification
     */
    error InvalidPubSignalsLength();

    /**
     * @notice Error thrown when the command length is invalid
     * @dev The command should have the expected format and length
     */
    error InvalidCommandLength();

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
     * @notice Packs a string into field elements for ZK circuit compatibility
     * @param _string The string to pack
     * @param paddedSize The target size after padding
     * @return fields The packed field elements
     */
    function packString(string memory _string, uint256 paddedSize) internal pure returns (uint256[] memory fields) {
        fields = packBytes2Fields(bytes(_string), paddedSize);
        return fields;
    }

    /**
     * @notice Packs a bytes32 value into a single field element
     * @param _bytes32 The bytes32 value to pack
     * @return fields The packed field element
     */
    function packBytes32(bytes32 _bytes32) internal pure returns (uint256[] memory fields) {
        fields = new uint256[](1);
        fields[0] = uint256(_bytes32);
        return fields;
    }

    /**
     * @notice Packs a boolean value into a single field element
     * @param b The boolean value to pack
     * @return fields The packed field element
     */
    function packBool(bool b) internal pure returns (uint256[] memory fields) {
        fields = new uint256[](1);
        fields[0] = b ? 1 : 0;
        return fields;
    }

    /**
     * @notice Packs a uint256 value into a single field element
     * @param _uint256 The uint256 value to pack
     * @return fields The packed field element
     */
    function packUint256(uint256 _uint256) internal pure returns (uint256[] memory fields) {
        fields = new uint256[](1);
        fields[0] = _uint256;
        return fields;
    }

    /**
     * @notice Packs a public key (as bytes) into field elements
     * @param pubKeyBytes The public key bytes (encoded as uint256[17])
     * @return fields The packed field elements
     */
    function packPubKey(bytes memory pubKeyBytes) internal pure returns (uint256[] memory fields) {
        uint256[17] memory pubKeyChunks = abi.decode(pubKeyBytes, (uint256[17]));
        fields = new uint256[](17);
        for (uint256 i = 0; i < 17; i++) {
            fields[i] = pubKeyChunks[i];
        }
        return fields;
    }

    /**
     * @notice Unpacks field elements back to bytes
     * @param _pucSignals Array of public signals
     * @param _startIndex Starting index in pubSignals
     * @param _paddedSize Original padded size of the bytes
     * @return The unpacked bytes
     */
    function unpackFields2Bytes(
        uint256[] calldata _pucSignals,
        uint256 _startIndex,
        uint256 _paddedSize
    )
        internal
        pure
        returns (bytes memory)
    {
        uint256 remain = _paddedSize % 31;
        uint256 numFields = (_paddedSize - remain) / 31;
        if (remain > 0) {
            numFields += 1;
        }

        bytes memory result = new bytes(_paddedSize);
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < numFields; i++) {
            uint256 field = _pucSignals[_startIndex + i];
            for (uint256 j = 0; j < 31 && resultIndex < _paddedSize; j++) {
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

    /**
     * @notice Unpacks field elements to a string
     * @param pubSignals Array of public signals
     * @param startIndex Starting index in pubSignals
     * @param paddedSize Original padded size of the string
     * @return The unpacked string
     */
    function unpackString(
        uint256[] calldata pubSignals,
        uint256 startIndex,
        uint256 paddedSize
    )
        internal
        pure
        returns (string memory)
    {
        return string(unpackFields2Bytes(pubSignals, startIndex, paddedSize));
    }

    /**
     * @notice Unpacks a bytes32 value from public signals
     * @param pubSignals Array of public signals
     * @param startIndex Starting index in pubSignals
     * @return The unpacked bytes32 value
     */
    function unpackBytes32(uint256[] calldata pubSignals, uint256 startIndex) internal pure returns (bytes32) {
        return bytes32(pubSignals[startIndex]);
    }

    /**
     * @notice Unpacks a uint256 value from public signals
     * @param pubSignals Array of public signals
     * @param startIndex Starting index in pubSignals
     * @return The unpacked uint256 value
     */
    function unpackUint256(uint256[] calldata pubSignals, uint256 startIndex) internal pure returns (uint256) {
        return pubSignals[startIndex];
    }

    /**
     * @notice Unpacks a boolean value from public signals
     * @param pubSignals Array of public signals
     * @param startIndex Starting index in pubSignals
     * @return The unpacked boolean value
     */
    function unpackBool(uint256[] calldata pubSignals, uint256 startIndex) internal pure returns (bool) {
        return pubSignals[startIndex] == 1;
    }

    /**
     * @notice Extracts miscellaneous data from public signals
     * @param pubSignals Array of public signals
     * @param startIndex Starting index of miscellaneous data
     * @return miscellaneousData The miscellaneous data
     */
    function unpackMiscellaneousData(
        uint256[] calldata pubSignals,
        uint256 startIndex
    )
        internal
        pure
        returns (bytes memory miscellaneousData)
    {
        uint256[17] memory pubKeyChunks;
        for (uint256 i = 0; i < pubKeyChunks.length; i++) {
            pubKeyChunks[i] = pubSignals[startIndex + i];
        }
        miscellaneousData = abi.encode(pubKeyChunks);
        return miscellaneousData;
    }

    /**
     * @notice Extracts the parts of an email address, replacing '@' with '$' and splitting by '.'
     * @param email The email address to process
     * @return The parts of the email address as a string array
     */
    function extractEmailParts(string memory email) internal pure returns (string[] memory) {
        bytes memory emailBytes = bytes(email);
        bytes memory modifiedEmail = new bytes(emailBytes.length);
        uint256 atIndex = 0;
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == "@") {
                modifiedEmail[i] = "$";
                atIndex = i;
            } else {
                modifiedEmail[i] = emailBytes[i];
            }
        }

        return _splitString(string(modifiedEmail), ".");
    }

    /**
     * @notice Verifies that the email parts are dot separated and match the claimed email
     * @param emailParts The parts of the email address dot separated
     * @param email The complete email address
     * @return True if the email parts are dot separated and match the claimed email, false otherwise
     */
    function verifyEmailParts(string[] memory emailParts, string memory email) internal pure returns (bool) {
        string memory composedEmail = "";
        for (uint256 i = 0; i < emailParts.length; i++) {
            composedEmail = string.concat(composedEmail, emailParts[i]);
            if (i < emailParts.length - 1) {
                composedEmail = string.concat(composedEmail, ".");
            }
        }

        bytes memory emailBytes = bytes(email);
        bytes memory composedEmailBytes = bytes(composedEmail);

        // Ensure composedEmail and emailBytes have the same length
        if (composedEmailBytes.length != emailBytes.length) {
            return false;
        }

        // check if the email parts are dot separated and match the claimed email
        // note since @ sign is not in ens encoding valid char set, we are arbitrarily replacing it with a $
        for (uint256 i = 0; i < emailBytes.length; i++) {
            bytes1 currentByte = emailBytes[i];
            if (currentByte == "@") {
                if (composedEmailBytes[i] != "$") {
                    return false;
                }
            } else if (currentByte != composedEmailBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Flattens multiple arrays of field elements into a single array of length 60
     * @param inputs The arrays of field elements to flatten
     * @return out The flattened array of length 60
     */
    function flattenFields(uint256[][] memory inputs) internal pure returns (uint256[60] memory out) {
        uint256 k = 0;
        for (uint256 i = 0; i < inputs.length; i++) {
            uint256[] memory arr = inputs[i];
            for (uint256 j = 0; j < arr.length; j++) {
                if (k >= 60) revert InvalidPubSignalsLength();
                out[k++] = arr[j];
            }
        }
        if (k != 60) revert InvalidPubSignalsLength();
        return out;
    }

    /// @notice Extracts a parameter from a command string based on the template and parameter index.
    /// @param template The command template as an array of strings.
    /// @param command The command string to extract from.
    /// @param paramIndex The zero-based index of the parameter to extract.
    /// @return The extracted parameter as a string, or an empty string if not found.
    function extractCommandParamByIndex(
        string[] memory template,
        string memory command,
        uint256 paramIndex
    )
        internal
        pure
        returns (string memory)
    {
        uint256 wordIndex = _getParamWordIndex(template, paramIndex);
        if (wordIndex == type(uint256).max) {
            return "";
        }

        return _splitString(command, " ")[wordIndex];
    }

    /**
     * @notice Checks if the given template string is a matcher (parameter placeholder).
     * @param templateString The template string to check.
     * @return True if the string is a matcher, false otherwise.
     */
    function _isMatcher(string memory templateString) private pure returns (bool) {
        return Strings.equal(templateString, CommandUtils.STRING_MATCHER)
            || Strings.equal(templateString, CommandUtils.UINT_MATCHER)
            || Strings.equal(templateString, CommandUtils.INT_MATCHER)
            || Strings.equal(templateString, CommandUtils.DECIMALS_MATCHER)
            || Strings.equal(templateString, CommandUtils.ETH_ADDR_MATCHER);
    }

    /**
     * @notice Finds the index in the template corresponding to the Nth matcher (zero-based).
     * @param template The command template as an array of strings.
     * @param paramIndex The zero-based index of the parameter to find.
     * @return paramTemplateIndex The zero-based index in the template array, or uint256 max if not found.
     */
    function _getParamWordIndex(
        string[] memory template,
        uint256 paramIndex
    )
        private
        pure
        returns (uint256 paramTemplateIndex)
    {
        paramTemplateIndex = 0;
        for (uint256 i = 0; i < template.length; i++) {
            if (_isMatcher(template[i])) {
                if (paramTemplateIndex == paramIndex) {
                    return i;
                }
                paramTemplateIndex++;
            }
        }

        // return uint max if param not found
        return type(uint256).max;
    }

    /**
     * @notice Splits a string by a delimiter into an array of strings
     * @param str The string to split
     * @param delimiter The delimiter to split by
     * @return The array of split strings
     */
    function _splitString(string memory str, bytes1 delimiter) private pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiter) {
                count++;
            }
        }

        string[] memory parts = new string[](count);
        uint256 lastIndex = 0;
        uint256 partIndex = 0;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiter) {
                bytes memory partBytes = strBytes.slice(lastIndex, i);
                parts[partIndex] = string(partBytes);
                lastIndex = i + 1;
                partIndex++;
            }
        }
        bytes memory lastPartBytes = strBytes.slice(lastIndex, strBytes.length);
        parts[partIndex] = string(lastPartBytes);
        return parts;
    }
}
