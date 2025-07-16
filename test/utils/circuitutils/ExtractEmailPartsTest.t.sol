// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { CircuitUtils } from "../../../src/utils/CircuitUtils.sol";

contract ExtractEmailPartsHelper {
    function callExtractEmailParts(string memory email) external view returns (string[] memory) {
        return CircuitUtils.extractEmailParts(email);
    }
}

contract ExtractEmailPartsTest is Test {
    ExtractEmailPartsHelper private _helper;

    function setUp() public {
        _helper = new ExtractEmailPartsHelper();
    }

    function test_expectRevert_emailWithAtSymbolAtStart() public {
        vm.expectRevert(CircuitUtils.InvalidEmailAddress.selector);
        _helper.callExtractEmailParts("@domain.com");
    }

    function test_expectRevert_emailWithAtSymbolAtEnd() public {
        vm.expectRevert(CircuitUtils.InvalidEmailAddress.selector);
        _helper.callExtractEmailParts("user@");
    }

    function test_expectRevert_emailWithOnlyAtSymbol() public {
        vm.expectRevert(CircuitUtils.InvalidEmailAddress.selector);
        _helper.callExtractEmailParts("@");
    }

    function test_expectRevert_emailWithoutAtSymbol() public {
        vm.expectRevert(CircuitUtils.InvalidEmailAddress.selector);
        _helper.callExtractEmailParts("user.domain.com");
    }

    function test_expectRevert_emailWithMultipleAtSymbols() public {
        vm.expectRevert(CircuitUtils.InvalidEmailAddress.selector);
        _helper.callExtractEmailParts("user@domain@test.com");
    }

    function test_emptyEmail() public {
        vm.expectRevert(CircuitUtils.InvalidEmailAddress.selector);
        _helper.callExtractEmailParts("");
    }

    function test_simpleEmail() public view {
        string memory email = "user@gmail.com";
        string[] memory parts = _helper.callExtractEmailParts(email);
        assertEq(parts.length, 2);
        assertEq(parts[0], "user$gmail");
        assertEq(parts[1], "com");
    }

    function test_emailWithSubdomain() public view {
        string memory email = "user@sub.domain.com";
        string[] memory parts = _helper.callExtractEmailParts(email);
        assertEq(parts.length, 3);
        assertEq(parts[0], "user$sub");
        assertEq(parts[1], "domain");
        assertEq(parts[2], "com");
    }

    function test_emailWithMultipleDots() public view {
        string memory email = "user@domain.co.uk";
        string[] memory parts = _helper.callExtractEmailParts(email);
        assertEq(parts.length, 3);
        assertEq(parts[0], "user$domain");
        assertEq(parts[1], "co");
        assertEq(parts[2], "uk");
    }

    function test_complexEmail() public view {
        string memory email = "user.name+tag@sub.domain.co.uk";
        string[] memory parts = _helper.callExtractEmailParts(email);
        assertEq(parts.length, 5);
        assertEq(parts[0], "user");
        assertEq(parts[1], "name+tag$sub");
        assertEq(parts[2], "domain");
        assertEq(parts[3], "co");
        assertEq(parts[4], "uk");
    }
}
