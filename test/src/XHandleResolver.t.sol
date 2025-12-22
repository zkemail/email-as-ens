// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { XHandleResolver } from "../../src/XHandleResolver.sol";
import { XHandleRegistrar } from "../../src/entrypoints/XHandleRegistrar.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ITextResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol";
import { IAddrResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import { NameCoder } from "@ensdomains/ens-contracts/contracts/utils/NameCoder.sol";
import { ClaimXHandleCommandVerifier } from "../../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { HonkVerifier } from "../fixtures/handleCommand/HonkVerifier.sol";
import { EnsUtils } from "../../src/utils/EnsUtils.sol";

contract XHandleResolverTest is Test {
    using EnsUtils for bytes;

    XHandleResolver public resolver;
    XHandleResolver public implementation;
    ERC1967Proxy public proxy;
    address public owner;

    XHandleRegistrar public registrar;
    bytes32 public rootNode;

    function setUp() public {
        owner = address(this);

        // Deploy implementation
        implementation = new XHandleResolver();

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(XHandleResolver.initialize.selector, address(0));
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

    function testResolveAddr() public {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(IAddrResolver.addr.selector, bytes32(0));

        // Should revert because registrar is not set (initialized with address(0))
        vm.expectRevert(abi.encodeWithSignature("RegistrarNotSet()"));
        resolver.resolve(name, data);
    }

    function testResolveAddrWithRegistrar() public {
        // Deploy a registrar
        address dkimRegistry = makeAddr("dkimRegistry");
        ClaimXHandleCommandVerifier verifier =
            new ClaimXHandleCommandVerifier(address(new HonkVerifier()), dkimRegistry);
        rootNode = bytes("x.zkemail.eth").namehash();
        registrar = new XHandleRegistrar(address(verifier), rootNode);

        // Set the registrar on the resolver
        resolver.setRegistrar(address(registrar));

        // Test resolving an address for a specific X handle
        string memory xHandle = "thezdev1";
        string memory ensName = string(abi.encodePacked(xHandle, ".x.zkemail.eth"));
        bytes memory dnsName = NameCoder.encode(ensName);

        // Calculate the ENS node
        bytes32 labelHash = keccak256(bytes(xHandle));
        bytes32 ensNode = keccak256(abi.encodePacked(rootNode, labelHash));

        // Get predicted address from registrar
        address predictedAddr = registrar.predictAddress(ensNode);

        // Resolve address through resolver
        bytes memory addrData = abi.encodeWithSelector(IAddrResolver.addr.selector, ensNode);
        bytes memory result = resolver.resolve(dnsName, addrData);
        address resolvedAddr = abi.decode(result, (address));

        // Verify they match
        assertEq(resolvedAddr, predictedAddr, "Resolver should return registrar's predicted address");
        assertTrue(resolvedAddr != address(0), "Resolved address should not be zero");
    }

    function testResolveUnsupportedSelector() public {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        // Use a random unsupported selector
        bytes4 unsupportedSelector = bytes4(keccak256("unsupported()"));
        bytes memory data = abi.encodePacked(unsupportedSelector, bytes32(0));

        vm.expectRevert(
            abi.encodeWithSelector(XHandleResolver.UnsupportedResolverProfile.selector, unsupportedSelector)
        );
        resolver.resolve(name, data);
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

    function testSupportsInterface() public view {
        // Test IExtendedResolver interface
        bytes4 extendedResolverInterface = 0x9061b923; // IExtendedResolver interfaceId
        assertTrue(resolver.supportsInterface(extendedResolverInterface));
    }

    function testResolveTextUnknownKey() public view {
        bytes memory name = NameCoder.encode("test.platform.zkemail.eth");
        bytes memory data = abi.encodeWithSelector(ITextResolver.text.selector, bytes32(0), "unknownKey");

        bytes memory result = resolver.resolve(name, data);
        string memory value = abi.decode(result, (string));

        assertEq(value, "", "Unknown text key should return empty string");
    }
}

