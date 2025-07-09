// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { CircuitUtils } from "../../../src/utils/CircuitUtils.sol";
import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { ProveAndClaimCommand } from "../../../src/utils/Verifier.sol";

contract UnpackFields2BytesTest is Test {
    function test_emptyFields() public pure {
        uint256[] memory fields = new uint256[](0);
        bytes memory result = _unpack(fields, 0, 0, 0);
        assertEq(result.length, 0);
    }

    function test_singleByte() public pure {
        uint256[] memory fields = new uint256[](1);
        fields[0] = 0x41;
        bytes memory result = _unpack(fields, 0, 1, 1);
        assertEq(result.length, 1);
        assertEq(uint8(result[0]), 0x41);
    }

    function test_singleFieldMultipleBytes() public pure {
        uint256[] memory fields = new uint256[](1);
        fields[0] = 0x41 + (0x42 << 8) + (0x43 << 16);
        bytes memory result = _unpack(fields, 0, 1, 3);
        assertEq(result.length, 3);
        assertEq(uint8(result[0]), 0x41);
        assertEq(uint8(result[1]), 0x42);
        assertEq(uint8(result[2]), 0x43);
    }

    function test_multipleFields() public pure {
        uint256[] memory fields = new uint256[](2);
        fields[0] = 0x41 + (0x42 << 8) + (0x43 << 16);
        fields[1] = 0x44 + (0x45 << 8) + (0x46 << 16);
        bytes memory result = _unpack(fields, 0, 2, 6);
        // Only the first 3 bytes are non-zero, the rest are trimmed
        assertEq(result.length, 3);
        assertEq(uint8(result[0]), 0x41);
        assertEq(uint8(result[1]), 0x42);
        assertEq(uint8(result[2]), 0x43);
    }

    function test_trimTrailingZeros() public pure {
        uint256[] memory fields = new uint256[](1);
        fields[0] = 0x41 + (0x42 << 8) + (0x00 << 16);
        bytes memory result = _unpack(fields, 0, 1, 3);
        assertEq(result.length, 2);
        assertEq(uint8(result[0]), 0x41);
        assertEq(uint8(result[1]), 0x42);
    }

    function test_zerosInMiddle() public pure {
        uint256[] memory fields = new uint256[](1);
        fields[0] = 0x41 + (0x00 << 8) + (0x43 << 16);
        bytes memory result = _unpack(fields, 0, 1, 3);
        assertEq(result.length, 3);
        assertEq(uint8(result[0]), 0x41);
        assertEq(uint8(result[1]), 0x00);
        assertEq(uint8(result[2]), 0x43);
    }

    function test_roundTrip() public pure {
        string memory originalString = "Hello, World! This is a test string.";
        bytes memory originalBytes = bytes(originalString);
        uint256[] memory fields = CircuitUtils.packBytes2Fields(originalBytes, 255);
        bytes memory unpackedBytes = _unpack(fields, 0, fields.length, 255);
        string memory unpackedString = string(unpackedBytes);
        assertEq(unpackedString, originalString);
    }

    function test_exactFieldBoundaries() public pure {
        bytes memory originalBytes = new bytes(31);
        for (uint256 i = 0; i < 31; i++) {
            originalBytes[i] = bytes1(uint8(i + 65));
        }
        uint256[] memory fields = CircuitUtils.packBytes2Fields(originalBytes, 31);
        bytes memory unpackedBytes = _unpack(fields, 0, fields.length, 31);
        assertEq(unpackedBytes.length, originalBytes.length);
        for (uint256 i = 0; i < originalBytes.length; i++) {
            assertEq(unpackedBytes[i], originalBytes[i]);
        }
    }

    function test_withOffset() public pure {
        uint256[] memory fields = new uint256[](3);
        fields[0] = 0x11 + (0x12 << 8);
        fields[1] = 0x21 + (0x22 << 8) + (0x23 << 16);
        fields[2] = 0x31 + (0x32 << 8);
        bytes memory result = _unpack(fields, 1, 1, 3);
        assertEq(result.length, 3);
        assertEq(uint8(result[0]), 0x21);
        assertEq(uint8(result[1]), 0x22);
        assertEq(uint8(result[2]), 0x23);
    }

    function test_withTestFixtures() public pure {
        (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals) = TestFixtures.claimEnsCommand();
        uint256[] memory publicSignals = new uint256[](60);
        for (uint256 i = 0; i < 60; i++) {
            publicSignals[i] = expectedPubSignals[i];
        }
        bytes memory domainBytes = _unpack(publicSignals, 0, 9, 255);
        string memory domain = string(domainBytes);
        assertEq(domain, command.domain);
        bytes memory emailBytes = _unpack(publicSignals, 51, 9, 256);
        string memory email = string(emailBytes);
        assertEq(email, command.email);
    }

    function test_moreFieldsThanAvailable() public pure {
        uint256[] memory fields = new uint256[](1);
        fields[0] = 0x41 + (0x42 << 8);
        bytes memory result = _unpack(fields, 0, 1, 4);
        assertEq(result.length, 2);
        assertEq(uint8(result[0]), 0x41);
        assertEq(uint8(result[1]), 0x42);
    }

    function test_allZeros() public pure {
        uint256[] memory fields = new uint256[](1);
        fields[0] = 0;
        bytes memory result = _unpack(fields, 0, 1, 31);
        assertEq(result.length, 0);
    }

    function test_maxFieldValue() public pure {
        uint256[] memory fields = new uint256[](1);
        fields[0] = 0;
        for (uint256 i = 0; i < 31; i++) {
            fields[0] += 0xFF << (8 * i);
        }
        bytes memory result = _unpack(fields, 0, 1, 31);
        assertEq(result.length, 31);
        for (uint256 i = 0; i < 31; i++) {
            assertEq(uint8(result[i]), 0xFF);
        }
    }

    function _unpack(
        uint256[] memory publicSignals,
        uint256 startIndex,
        uint256 numFields,
        uint256 paddedSize
    )
        private
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
        uint256 actualLength = 0;
        for (uint256 i = 0; i < result.length; i++) {
            if (result[i] != 0) {
                actualLength = i + 1;
            }
        }
        bytes memory trimmedResult = new bytes(actualLength);
        for (uint256 i = 0; i < actualLength; i++) {
            trimmedResult[i] = result[i];
        }
        return trimmedResult;
    }
}
