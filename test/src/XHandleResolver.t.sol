// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test, console } from "forge-std/Test.sol";
import { XHandleResolver } from "../../src/XHandleResolver.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ITextResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol";
import { IAddrResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import { NameCoder } from "@ensdomains/ens-contracts/contracts/utils/NameCoder.sol";

contract XHandleResolverTest is Test {
    XHandleResolver public resolver;
    XHandleResolver public implementation;
    ERC1967Proxy public proxy;
    address public owner;

    function setUp() public {
        owner = address(this);

        // Deploy implementation
        implementation = new XHandleResolver();

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(XHandleResolver.initialize.selector);
        proxy = new ERC1967Proxy(address(implementation), initData);

        // Cast proxy to XHandleResolver interface
        resolver = XHandleResolver(address(proxy));
    }

    function testUpgrade() public {
        // Deploy new implementation
        XHandleResolver newImplementation = new XHandleResolver();

        // Upgrade
        resolver.upgradeToAndCall(address(newImplementation), "");

        // Verify upgrade worked - resolver should still be functional
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "description");

        bytes memory result = resolver.resolve(name, data);
        string memory description = abi.decode(result, (string));

        assertEq(description, "Claim your tips from the zkEmail dashboard");
    }

    function testUpgradeOnlyOwner() public {
        XHandleResolver newImplementation = new XHandleResolver();

        // Try to upgrade from non-owner account
        vm.prank(address(0x123));
        vm.expectRevert();
        resolver.upgradeToAndCall(address(newImplementation), "");
    }

    function testInitialization() public view {
        assertEq(resolver.owner(), owner);
    }

    function testResolveTextDescription() public view {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "description");

        bytes memory result = resolver.resolve(name, data);
        string memory description = abi.decode(result, (string));

        assertEq(description, "Claim your tips from the zkEmail dashboard");
    }

    function testResolveTextUrl() public view {
        bytes memory name = NameCoder.encode("myhandle.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "url");

        bytes memory result = resolver.resolve(name, data);
        string memory url = abi.decode(result, (string));

        assertEq(url, "https://zk.email/myhandle.platform.zkemail.eth");
    }

    function testResolveAddr() public view {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(IAddrResolver.addr.selector, bytes32(0));

        bytes memory result = resolver.resolve(name, data);
        address addr = abi.decode(result, (address));

        // Verify it returns a deterministic address
        address expected = address(uint160(uint256(keccak256(abi.encode("test.platform.zkemail.eth")))));
        assertEq(addr, expected);
    }

    function testSupportsInterface() public view {
        // Test IExtendedResolver interface
        bytes4 extendedResolverInterface = 0x9061b923; // IExtendedResolver interfaceId
        assertTrue(resolver.supportsInterface(extendedResolverInterface));
    }
}

