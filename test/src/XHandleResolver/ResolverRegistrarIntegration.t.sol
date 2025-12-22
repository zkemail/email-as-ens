// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { XHandleResolver } from "../../../src/XHandleResolver.sol";
import { XHandleRegistrar } from "../../../src/entrypoints/XHandleRegistrar.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IAddrResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import { NameCoder } from "@ensdomains/ens-contracts/contracts/utils/NameCoder.sol";
import {
    ClaimXHandleCommand,
    ClaimXHandleCommandVerifier
} from "../../../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { HonkVerifier } from "../../fixtures/handleCommand/HonkVerifier.sol";
import { HandleCommandTestFixture } from "../../fixtures/handleCommand/HandleCommandTestFixture.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { EnsUtils } from "../../../src/utils/EnsUtils.sol";

contract ResolverRegistrarIntegrationTest is Test {
    using EnsUtils for bytes;

    XHandleResolver internal _resolver;
    XHandleRegistrar internal _registrar;
    ClaimXHandleCommandVerifier internal _verifier;
    address internal _dkimRegistry;
    bytes32 internal _rootNode;

    ClaimXHandleCommand internal _validCommand;
    bytes internal _validEncodedCommand;
    bytes32 internal _ensNode;

    function setUp() public {
        // Get the valid command from fixture
        (_validCommand,) = HandleCommandTestFixture.getClaimXFixture();

        // Setup DKIM registry mock
        _dkimRegistry = makeAddr("dkimRegistry");
        vm.mockCall(
            _dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(_validCommand.publicInputs.senderDomain)),
                _validCommand.publicInputs.pubkeyHash
            ),
            abi.encode(true)
        );

        // Calculate root node: namehash("x.zkemail.eth")
        _rootNode = bytes("x.zkemail.eth").namehash();

        // Deploy verifier and registrar
        _verifier = new ClaimXHandleCommandVerifier(address(new HonkVerifier()), _dkimRegistry);
        _registrar = new XHandleRegistrar(address(_verifier), _rootNode);

        // Deploy resolver with proxy
        XHandleResolver implementation = new XHandleResolver();
        bytes memory initData = abi.encodeWithSelector(XHandleResolver.initialize.selector, address(_registrar));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        _resolver = XHandleResolver(address(proxy));

        // Calculate ENS node from x handle
        bytes32 labelHash = keccak256(bytes(_validCommand.publicInputs.xHandle));
        _ensNode = keccak256(abi.encodePacked(_rootNode, labelHash));
        _validEncodedCommand = abi.encode(_validCommand);
    }

    function test_ResolverRevertsWhenRegistrarNotSet() public {
        // Deploy a new resolver without setting registrar
        XHandleResolver implementation = new XHandleResolver();
        bytes memory initData = abi.encodeWithSelector(XHandleResolver.initialize.selector, address(0));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        XHandleResolver resolverWithoutRegistrar = XHandleResolver(address(proxy));

        // Construct DNS-encoded name
        string memory ensName = string(abi.encodePacked(_validCommand.publicInputs.xHandle, ".x.zkemail.eth"));
        bytes memory dnsEncodedName = NameCoder.encode(ensName);

        // Get address from resolver - should revert with RegistrarNotSet
        bytes memory addrCall = abi.encodeWithSelector(IAddrResolver.addr.selector, _ensNode);

        vm.expectRevert(abi.encodeWithSignature("RegistrarNotSet()"));
        resolverWithoutRegistrar.resolve(dnsEncodedName, addrCall);
    }

    function test_ResolverReturnsDeployedAddressAfterClaim() public {
        // Pre-fund the predicted address
        address predictedAddr = _registrar.predictAddress(_ensNode);
        vm.deal(predictedAddr, 1 ether);

        // Claim the handle (deploys account and withdraws)
        address deployedAccount = _registrar.claimAndWithdraw(_validEncodedCommand);

        // Get address from registrar
        address registrarAddr = _registrar.getAccount(_ensNode);

        // Construct DNS-encoded name
        string memory ensName = string(abi.encodePacked(_validCommand.publicInputs.xHandle, ".x.zkemail.eth"));
        bytes memory dnsEncodedName = NameCoder.encode(ensName);

        // Get address from resolver
        bytes memory addrCall = abi.encodeWithSelector(IAddrResolver.addr.selector, _ensNode);
        bytes memory result = _resolver.resolve(dnsEncodedName, addrCall);
        address resolverAddr = abi.decode(result, (address));

        // All three should match
        assertEq(deployedAccount, registrarAddr, "Deployed account should match registrar getAccount");
        assertEq(resolverAddr, registrarAddr, "Resolver should return same address as registrar");
        assertEq(resolverAddr, deployedAccount, "Resolver should return deployed account address");
    }

    function test_ResolverUpdatesWhenRegistrarChanged() public {
        // Get initial predicted address
        address initialPredicted = _registrar.predictAddress(_ensNode);
        string memory ensName = string(abi.encodePacked(_validCommand.publicInputs.xHandle, ".x.zkemail.eth"));
        bytes memory dnsName = NameCoder.encode(ensName);
        bytes memory addrCall = abi.encodeWithSelector(IAddrResolver.addr.selector, _ensNode);
        bytes memory result1 = _resolver.resolve(dnsName, addrCall);
        address initialResolved = abi.decode(result1, (address));
        assertEq(initialResolved, initialPredicted, "Initial addresses should match");

        // Deploy a new registrar with different root node
        bytes32 newRootNode = bytes("different.root.eth").namehash();
        XHandleRegistrar newRegistrar = new XHandleRegistrar(address(_verifier), newRootNode);

        // Update resolver to use new registrar
        _resolver.setRegistrar(address(newRegistrar));

        // Calculate new ENS node with new root
        bytes32 newLabelHash = keccak256(bytes(_validCommand.publicInputs.xHandle));
        bytes32 newEnsNode = keccak256(abi.encodePacked(newRootNode, newLabelHash));

        // Get address from new registrar
        address newPredicted = newRegistrar.predictAddress(newEnsNode);

        // Get address from resolver (using new ENS node)
        bytes memory addrCall2 = abi.encodeWithSelector(IAddrResolver.addr.selector, newEnsNode);
        bytes memory result2 = _resolver.resolve(dnsName, addrCall2);
        address newResolved = abi.decode(result2, (address));

        assertEq(newResolved, newPredicted, "Addresses should match with new registrar");
        assertTrue(newResolved != initialResolved, "New registrar should produce different addresses");
    }

    function test_ResolverReturnsPredictedAddressBeforeClaim() public view {
        // Get predicted address from registrar
        address registrarPredicted = _registrar.predictAddress(_ensNode);

        // Construct DNS-encoded name for the x handle
        string memory ensName = string(abi.encodePacked(_validCommand.publicInputs.xHandle, ".x.zkemail.eth"));
        bytes memory dnsEncodedName = NameCoder.encode(ensName);

        // Get address from resolver using addr(node)
        bytes memory addrCall = abi.encodeWithSelector(IAddrResolver.addr.selector, _ensNode);
        bytes memory result = _resolver.resolve(dnsEncodedName, addrCall);
        address resolverAddr = abi.decode(result, (address));

        // They should match
        assertEq(resolverAddr, registrarPredicted, "Resolver should return same predicted address as registrar");
    }

    function test_ResolverAddressMatchesForMultipleHandles() public view {
        // Test with first handle
        address predicted1 = _registrar.predictAddress(_ensNode);
        string memory ensName1 = string(abi.encodePacked(_validCommand.publicInputs.xHandle, ".x.zkemail.eth"));
        bytes memory dnsName1 = NameCoder.encode(ensName1);
        bytes memory addrCall1 = abi.encodeWithSelector(IAddrResolver.addr.selector, _ensNode);
        bytes memory result1 = _resolver.resolve(dnsName1, addrCall1);
        address resolved1 = abi.decode(result1, (address));
        assertEq(resolved1, predicted1, "First handle addresses should match");

        // Create and test with second handle
        ClaimXHandleCommand memory command2 = _validCommand;
        command2.publicInputs.xHandle = "differenthandle";
        command2.publicInputs.emailNullifier = keccak256("nullifier2");

        bytes32 labelHash2 = keccak256(bytes(command2.publicInputs.xHandle));
        bytes32 ensNode2 = keccak256(abi.encodePacked(_rootNode, labelHash2));

        address predicted2 = _registrar.predictAddress(ensNode2);
        string memory ensName2 = string(abi.encodePacked(command2.publicInputs.xHandle, ".x.zkemail.eth"));
        bytes memory dnsName2 = NameCoder.encode(ensName2);
        bytes memory addrCall2 = abi.encodeWithSelector(IAddrResolver.addr.selector, ensNode2);
        bytes memory result2 = _resolver.resolve(dnsName2, addrCall2);
        address resolved2 = abi.decode(result2, (address));

        assertEq(resolved2, predicted2, "Second handle addresses should match");
        assertTrue(resolved1 != resolved2, "Different handles should have different addresses");
    }
}

