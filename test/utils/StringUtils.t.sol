// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { StringUtils } from "../../src/utils/StringUtils.sol";

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
}
