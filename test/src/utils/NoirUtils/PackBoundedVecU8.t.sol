// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { NoirUtilsHelper } from "./_NoirUtilsHelper.sol";

contract PackBoundedVecU8Test is Test {
    NoirUtilsHelper private _helper;

    function setUp() public {
        _helper = new NoirUtilsHelper();
    }

    function test_pack_revertsWhenInputTooLong() public {
        string memory input = "toolong"; // length 7
        uint256 numFields = 6; // cannot fit length 7 (length slot is included in numFields)

        vm.expectRevert();
        _helper.callPackBoundedVecU8(input, numFields);
    }

    // TODO: fix code and uncomment this test
    // function test_pack_revertsWhenInputLengthEqualsNumFields() public {
    //     string memory input = "abcdef"; // length 6
    //     uint256 numFields = 6; // needs 6 data slots + 1 length slot, so this should revert

    //     vm.expectRevert();
    //     _helper.callPackBoundedVecU8(input, numFields);
    // }

    function test_packThenUnpack_roundtrip() public view {
        string memory input = "hello"; // length 5
        uint256 numFields = 8; // includes last slot for length

        bytes32[] memory packed = _helper.callPackBoundedVecU8(input, numFields);

        // first 5 entries are the ASCII codes
        assertEq(packed[0], bytes32(uint256(uint8(bytes(input)[0]))));
        assertEq(packed[1], bytes32(uint256(uint8(bytes(input)[1]))));
        assertEq(packed[2], bytes32(uint256(uint8(bytes(input)[2]))));
        assertEq(packed[3], bytes32(uint256(uint8(bytes(input)[3]))));
        assertEq(packed[4], bytes32(uint256(uint8(bytes(input)[4]))));

        // unused data slots remain zeroed
        assertEq(packed[5], bytes32(0));
        // last element is the length
        assertEq(packed[numFields - 1], bytes32(uint256(bytes(input).length)));

        // round-trip via unpack
        string memory unpacked = _helper.callUnpackBoundedVecU8(packed);
        assertEq(unpacked, input);
    }
}
