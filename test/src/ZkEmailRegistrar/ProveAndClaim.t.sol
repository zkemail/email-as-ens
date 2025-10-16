// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { Test } from "forge-std/Test.sol";
import {
    ProveAndClaimCommand, ProveAndClaimCommandVerifier
} from "../../../src/verifiers/ProveAndClaimCommandVerifier.sol";
import { EnsUtils } from "../../../src/utils/EnsUtils.sol";
import { Groth16Verifier } from "../../fixtures/Groth16Verifier.sol";
import { IResolver, ZkEmailRegistrar } from "../../../src/ZkEmailRegistrar.sol";
import { ENSRegistry } from "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { ZkEmailRegistrarHelper } from "./_ZkEmailRegistrarHelper.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract ProveAndClaimTest is Test {
    using Bytes for bytes;
    using EnsUtils for bytes;

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
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        address dkimRegistry = makeAddr("dkimRegistry");
        vm.mockCall(
            dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(command.emailAuthProof.publicInputs.domainName)),
                command.emailAuthProof.publicInputs.publicKeyHash
            ),
            abi.encode(true)
        );
        verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()), dkimRegistry);

        // setup ENS registry
        vm.startPrank(owner);
        ens = new ENSRegistry();
        ens.setSubnodeOwner(ROOT_NODE, keccak256(bytes("eth")), owner);
        vm.stopPrank();

        registrar = new ZkEmailRegistrarHelper(ZKEMAIL_NODE, address(verifier), address(ens));

        vm.prank(owner);
        ens.setSubnodeOwner(ETH_NODE, keccak256(bytes("zk")), address(registrar));
    }

    function test_passesForValidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName =
            abi.encodePacked(bytes(command.emailAuthProof.publicInputs.emailAddress), bytes(".zk.eth"));
        bytes32 expectedNode = expectedEnsName.namehash();
        bytes32 resolverNode = bytes(command.resolver).namehash();

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

    function test_revertsWhen_doubleUseOfNullifier() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName =
            abi.encodePacked(bytes(command.emailAuthProof.publicInputs.emailAddress), bytes(".zk.eth"));
        bytes32 expectedNode = expectedEnsName.namehash();
        bytes32 resolverNode = bytes(command.resolver).namehash();

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

    function test_revertsWhen_invalidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        command.emailAuthProof.publicInputs.emailAddress = "bob@example.com";
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.InvalidCommand.selector));
        registrar.entrypoint(abi.encode(command));
    }

    function _mockAndExpect(address target, bytes memory call, bytes memory ret) internal {
        vm.mockCall(target, call, ret);
        vm.expectCall(target, call);
    }
}
