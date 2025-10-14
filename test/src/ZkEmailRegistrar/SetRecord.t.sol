// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { TestFixtures } from "../../fixtures/TestFixtures.sol";
import { TestUtils } from "../../TestUtils.sol";
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

contract SetRecordTest is TestUtils {
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
        address dkimRegistry = _createMockDkimRegistry(
            command.emailAuthProof.publicInputs.domainName, command.emailAuthProof.publicInputs.publicKeyHash
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

    function test_revertsWhen_nonOwner() public {
        bytes32 node = abi.encodePacked(bytes("zk.eth")).namehash();
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.NotOwner.selector));
        registrar.setRecord(node, owner, address(0), 0);
    }

    function test_setsRecordCorrectlyIfOwner() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName =
            abi.encodePacked(bytes(command.emailAuthProof.publicInputs.emailAddress), bytes(".zk.eth"));
        bytes32 expectedNode = expectedEnsName.namehash();
        bytes32 resolverNode = bytes(command.resolver).namehash();

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
}
