// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "../fixtures/TestFixtures.sol";
import {
    ProveAndClaimCommand, ProveAndClaimCommandVerifier
} from "../../src/verifiers/ProveAndClaimCommandVerifier.sol";
import { Groth16Verifier } from "../fixtures/Groth16Verifier.sol";
import { IResolver, ZkEmailRegistrar } from "../../src/ZkEmailRegistrar.sol";
import { ENSRegistry } from "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { ZkEmailRegistrarHelper } from "./_ZkEmailRegistrarHelper.sol";

contract ZkEmailRegistrarTest is Test {
    using Bytes for bytes;

    // namehash(0)
    bytes32 public constant ROOT_NODE = 0x0;
    // namehash(zk.eth)
    bytes32 public constant ZKEMAIL_NODE = 0xc415680e10d4f52260859f9d558b33c0bd5d28ec16d9ae046d2695cb7144ee64;
    // namehash(eth)
    bytes32 public constant ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
    // will be owner of root(namehash(0)), and namehash(eth) domain
    address public owner = makeAddr("owner");

    ProveAndClaimCommandVerifier public verifier;
    ZkEmailRegistrarHelper public registrar;
    ENSRegistry public ens;

    function setUp() public {
        verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));

        // setup ENS registry
        vm.startPrank(owner);
        ens = new ENSRegistry();
        ens.setSubnodeOwner(ROOT_NODE, keccak256(bytes("eth")), owner);
        vm.stopPrank();

        registrar = new ZkEmailRegistrarHelper(ZKEMAIL_NODE, address(verifier), address(ens));

        vm.prank(owner);
        ens.setSubnodeOwner(ETH_NODE, keccak256(bytes("zk")), address(registrar));
    }

    function test_proveAndClaim_passesForValidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName = abi.encodePacked(bytes(command.proof.fields.emailAddress), bytes(".zk.eth"));
        bytes32 expectedNode = _nameHash(expectedEnsName, 0);
        bytes32 resolverNode = _nameHash(bytes(command.resolver), 0);

        // check that the node is not owned by anyone
        address ownerBefore = ens.owner(expectedNode);
        address ownerBeforeInRegistrar = registrar.owner(expectedNode);
        assertEq(ownerBefore, address(0));
        assertEq(ownerBeforeInRegistrar, address(0));

        address resolver = makeAddr("resolver");
        address resolverResolver = makeAddr("resolverResolver");
        _mockAndExpect(resolver, abi.encodeCall(IResolver.setAddr, (expectedNode, command.owner)), "");
        _mockAndExpect(resolver, abi.encodeCall(IResolver.approve, (expectedNode, command.owner, true)), "");
        _mockAndExpect(resolver, abi.encodeCall(IResolver.approve, (expectedNode, command.owner, false)), "");
        _mockAndExpect(address(ens), abi.encodeCall(ENS.resolver, (resolverNode)), abi.encode(resolverResolver));
        _mockAndExpect(resolverResolver, abi.encodeCall(IResolver.addr, (resolverNode)), abi.encode(resolver));

        registrar.entrypoint(abi.encode(command));

        // check ownership has been set in both ENS and registrar correctly
        address ownerAfter = ens.owner(expectedNode);
        address ownerAfterInRegistrar = registrar.owner(expectedNode);
        assertEq(ownerAfter, address(registrar));
        assertEq(ownerAfterInRegistrar, command.owner);
    }

    function test_proveAndClaim_preventsDoubleUseOfNullifier() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName = abi.encodePacked(bytes(command.proof.fields.emailAddress), bytes(".zk.eth"));
        bytes32 expectedNode = _nameHash(expectedEnsName, 0);
        bytes32 resolverNode = _nameHash(bytes(command.resolver), 0);

        address resolver = makeAddr("resolver");
        address resolverResolver = makeAddr("resolverResolver");
        _mockAndExpect(resolver, abi.encodeCall(IResolver.setAddr, (expectedNode, command.owner)), "");
        _mockAndExpect(resolver, abi.encodeCall(IResolver.approve, (expectedNode, command.owner, true)), "");
        _mockAndExpect(resolver, abi.encodeCall(IResolver.approve, (expectedNode, command.owner, false)), "");
        _mockAndExpect(address(ens), abi.encodeCall(ENS.resolver, (resolverNode)), abi.encode(resolverResolver));
        _mockAndExpect(resolverResolver, abi.encodeCall(IResolver.addr, (resolverNode)), abi.encode(resolver));

        registrar.entrypoint(abi.encode(command)); // passes the first time

        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.NullifierUsed.selector));
        registrar.entrypoint(abi.encode(command)); // fails the second time
    }

    function test_setRecord_revertsForNonOwner() public {
        bytes32 node = _nameHash(abi.encodePacked(bytes("zk.eth")), 0);
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.NotOwner.selector));
        registrar.setRecord(node, owner, address(0), 0);
    }

    function test_setRecord_setsRecordCorrectlyIfOwner() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName = abi.encodePacked(bytes(command.proof.fields.emailAddress), bytes(".zk.eth"));
        bytes32 expectedNode = _nameHash(expectedEnsName, 0);
        bytes32 resolverNode = _nameHash(bytes(command.resolver), 0);

        address initialResolver = makeAddr("initialResolver");
        address resolverResolver = makeAddr("resolverResolver");
        _mockAndExpect(initialResolver, abi.encodeCall(IResolver.setAddr, (expectedNode, command.owner)), "");
        _mockAndExpect(initialResolver, abi.encodeCall(IResolver.approve, (expectedNode, command.owner, true)), "");
        _mockAndExpect(initialResolver, abi.encodeCall(IResolver.approve, (expectedNode, command.owner, false)), "");
        _mockAndExpect(address(ens), abi.encodeCall(ENS.resolver, (resolverNode)), abi.encode(resolverResolver));
        _mockAndExpect(resolverResolver, abi.encodeCall(IResolver.addr, (resolverNode)), abi.encode(initialResolver));

        registrar.entrypoint(abi.encode(command));

        address resolverBefore = ens.resolver(expectedNode);
        assertEq(resolverBefore, initialResolver);

        address newResolver = makeAddr("newResolver");
        address newOwner = makeAddr("newOwner");

        _mockAndExpect(newResolver, abi.encodeCall(IResolver.approve, (expectedNode, command.owner, false)), "");
        _mockAndExpect(newResolver, abi.encodeCall(IResolver.approve, (expectedNode, newOwner, true)), "");
        vm.prank(command.owner);
        registrar.setRecord(expectedNode, newOwner, newResolver, 0);

        // check that the record has been set correctly
        address ownerAfter = ens.owner(expectedNode); // should still be registrar
        address ownerAfterInRegistrar = registrar.owner(expectedNode);
        assertEq(ownerAfter, address(registrar));
        assertEq(ownerAfterInRegistrar, newOwner);
    }

    function test_proveAndClaim_revertsForInvalidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        command.proof.fields.emailAddress = "bob@example.com";
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.InvalidCommand.selector));
        registrar.entrypoint(abi.encode(command));
    }

    function test_setup() public view {
        address rootOwner = ens.owner(ROOT_NODE);
        address ethOwner = ens.owner(ETH_NODE);
        address zkOwner = ens.owner(ZKEMAIL_NODE);

        assertEq(rootOwner, owner);
        assertEq(ethOwner, owner);
        assertEq(zkOwner, address(registrar));
    }

    function test_nameHash_returnsCorrectHash() public pure {
        bytes memory nameBytes = "thezdev3$gmail.com.zk.eth";
        bytes32 expectedHash = 0xd3f54039086a0b9a16feda37bd0cb0dc73ef8ed3449303620fd902e2d1e38c54;
        bytes32 actualHash = _nameHash(nameBytes, 0);
        assertEq(actualHash, expectedHash);
    }

    function _mockAndExpect(address target, bytes memory call, bytes memory ret) internal {
        vm.mockCall(target, call, ret);
        vm.expectCall(target, call);
    }

    function _nameHash(bytes memory name, uint256 offset) internal pure returns (bytes32) {
        uint256 atSignIndex = name.indexOf(0x40);
        if (atSignIndex != type(uint256).max) {
            name[atSignIndex] = bytes1("$");
        }

        uint256 len = name.length;

        if (offset >= len) {
            return bytes32(0);
        }

        uint256 labelEnd = Math.min(name.indexOf(0x2E, offset), len);
        bytes memory label = name.slice(offset, labelEnd);
        bytes32 labelHash = keccak256(label);

        // Recursive case: hash of (parent nameHash + current labelHash)
        return keccak256(abi.encodePacked(_nameHash(name, labelEnd + 1), labelHash));
    }
}
