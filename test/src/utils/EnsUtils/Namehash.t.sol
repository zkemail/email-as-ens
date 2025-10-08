// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { EnsUtilsHelper } from "./_EnsUtilsHelper.sol";

contract NamehashTest is Test {
    EnsUtilsHelper private _helper;

    function setUp() public {
        _helper = new EnsUtilsHelper();
    }

    function test_eth() public view {
        bytes memory name = "eth";
        bytes32 result = _helper.callNamehash(name);
        assertEq(result, 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae);
    }

    function test_foo_eth() public view {
        bytes memory name = "foo.eth";
        bytes32 result = _helper.callNamehash(name);
        bytes32 expected = keccak256(
            abi.encodePacked(hex"93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae", keccak256("foo"))
        );
        assertEq(result, expected);
    }

    function test_email() public view {
        bytes memory name = "user@gmail.com";
        bytes32 result = _helper.callNamehash(name);

        bytes32 rootNode = bytes32(0);
        bytes32 comNode = keccak256(abi.encodePacked(rootNode, keccak256("com")));
        bytes32 gmailNode = keccak256(abi.encodePacked(comNode, keccak256("user$gmail")));
        assertEq(result, gmailNode);
    }

    function test_email_with_subdomain() public view {
        bytes memory name = "user@sub.domain.com";
        bytes32 result = _helper.callNamehash(name);

        bytes32 rootNode = bytes32(0);
        bytes32 comNode = keccak256(abi.encodePacked(rootNode, keccak256("com")));
        bytes32 domainNode = keccak256(abi.encodePacked(comNode, keccak256("domain")));
        bytes32 subNode = keccak256(abi.encodePacked(domainNode, keccak256("user$sub")));
        assertEq(result, subNode);
    }

    function test_empty() public view {
        bytes memory name = "";
        bytes32 result = _helper.callNamehash(name);
        assertEq(result, bytes32(0));
    }

    function test_actual_email_as_ens_name() public view {
        bytes memory name = "thezdev3$gmail.com.zk.eth";
        bytes32 result = _helper.callNamehash(name);
        assertEq(result, 0xd3f54039086a0b9a16feda37bd0cb0dc73ef8ed3449303620fd902e2d1e38c54);
    }
}
