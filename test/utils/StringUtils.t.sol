// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { StringUtils } from "../../src/utils/StringUtils.sol";
import "forge-std/console.sol";

contract StringUtilsTest is Test {
    function testFieldToAscii_Gmail() public {
        uint256 field = 2_018_721_414_038_404_820_327;
        string memory expected = "gmail.com";
        string memory result = StringUtils.fieldToAscii(field);
        assertEq(result, expected);
    }

    function testFieldToAscii_Empty() public {
        uint256 field = 0;
        string memory expected = "";
        string memory result = StringUtils.fieldToAscii(field);
        assertEq(result, expected);
    }

    function testFieldToAscii_LeadingZerosInValue() public {
        // "test" reversed is "tset", which in hex is 0x74736574
        uint256 field = 0x74736574;
        string memory expected = "test";
        string memory result = StringUtils.fieldToAscii(field);
        assertEq(result, expected);
    }

    function testFieldToAscii_TrailingNulls() public {
        // "tset\x00\x00" in hex is 0x747365740000
        uint256 field = 0x747365740000;
        string memory expected = "test";
        string memory result = StringUtils.fieldToAscii(field);
        assertEq(result, expected, "trailing nulls failed");
    }

    function testFieldToAscii_Full() public {
        // A full 32 byte string, reversed
        bytes32 val = "abcdefghijklmnopqrstuvwxyz123456";
        uint256 field = uint256(val);
        // The reverse of that:
        string memory expected = "654321zyxwvutsrqponmlkjihgfedcba";
        string memory result = StringUtils.fieldToAscii(field);
        assertEq(result, expected);
    }

    function testBytesToFieldsAndBack() public {
        string memory original =
            "This is a test string for the purpose of testing bytesToFields and fieldsToBytes conversion.";
        bytes memory originalBytes = bytes(original);
        uint256 paddedSize = originalBytes.length;
        if (paddedSize % 31 != 0) {
            paddedSize = (paddedSize / 31 + 1) * 31;
        }

        uint256[] memory fields = StringUtils.bytesToFields(originalBytes, paddedSize);
        bytes memory reconstructedBytes = StringUtils.fieldsToBytes(fields, originalBytes.length);

        assertEq(reconstructedBytes, originalBytes);
    }

    function benchmarkBytesToFields() public {
        string memory text =
            "This is a test string for benchmarking field conversion operations.";
        bytes memory textBytes = bytes(text);
        uint256 paddedSize = textBytes.length;
        if (paddedSize % 31 != 0) {
            paddedSize = (paddedSize / 31 + 1) * 31;
        }

        vm.txGasPrice(1);
        uint256 gasStart = gasleft();
        uint256[] memory fields = StringUtils.bytesToFields(textBytes, paddedSize);
        uint256 gasEnd = gasleft();
        console.log("Gas for bytesToFields:", gasStart - gasEnd);
        // Prevent unused variable warning
        fields[0] = fields[0];
    }

    function benchmarkFieldsToBytes() public {
        string memory text =
            "This is a test string for benchmarking field conversion operations.";
        bytes memory textBytes = bytes(text);
        uint256 paddedSize = textBytes.length;
        if (paddedSize % 31 != 0) {
            paddedSize = (paddedSize / 31 + 1) * 31;
        }
        uint256[] memory fields = StringUtils.bytesToFields(textBytes, paddedSize);

        vm.txGasPrice(1);
        uint256 gasStart = gasleft();
        bytes memory reconstructedBytes = StringUtils.fieldsToBytes(fields, textBytes.length);
        uint256 gasEnd = gasleft();
        console.log("Gas for fieldsToBytes:", gasStart - gasEnd);
        assertEq(reconstructedBytes, textBytes, "Reconstructed bytes should match original");
    }
}
