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

    function packString(string memory _string, uint256 paddedSize) internal pure returns (uint256[] memory fields) {
        fields = packBytes2Fields(bytes(_string), paddedSize);
        return fields;
    }

    function packBytes32(bytes32 _bytes32) internal pure returns (uint256[] memory fields) {
        fields = new uint256[](1);
        fields[0] = uint256(_bytes32);
        return fields;
    }

    function packBool(bool b) internal pure returns (uint256[] memory fields) {
        fields = new uint256[](1);
        fields[0] = b ? 1 : 0;
        return fields;
    }

    function packUint256(uint256 _uint256) internal pure returns (uint256[] memory fields) {
        fields = new uint256[](1);
        fields[0] = _uint256;
        return fields;
    }

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

    function unpackBytes32(uint256[] calldata pubSignals, uint256 startIndex) internal pure returns (bytes32) {
        return bytes32(pubSignals[startIndex]);
    }

    function unpackUint256(uint256[] calldata pubSignals, uint256 startIndex) internal pure returns (uint256) {
        return pubSignals[startIndex];
    }

    function unpackBool(uint256[] calldata pubSignals, uint256 startIndex) internal pure returns (bool) {
        return pubSignals[startIndex] == 1;
    }

    /**
     * @notice Extracts pubkey fields from public signals
     * @param pubSignals Array of public signals
     * @param startIndex Starting index of pubkey fields
     * @return pubKeyBytes The pubkey bytes
     */
    function unpackPubKey(
        uint256[] calldata pubSignals,
        uint256 startIndex
    )
        internal
        pure
        returns (bytes memory pubKeyBytes)
    {
        uint256[17] memory pubKeyChunks;
        for (uint256 i = 0; i < pubKeyChunks.length; i++) {
            pubKeyChunks[i] = pubSignals[startIndex + i];
        }
        pubKeyBytes = abi.encode(pubKeyChunks);
        return pubKeyBytes;
    }
}
