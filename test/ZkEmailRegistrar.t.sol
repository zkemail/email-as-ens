// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "./fixtures/TestFixtures.sol";
import { ProveAndClaimCommand, ProveAndClaimCommandVerifier } from "../src/utils/Verifier.sol";
import { Groth16Verifier } from "./fixtures/Groth16Verifier.sol";
import { ZkEmailRegistrar } from "../src/ZkEmailRegistrar.sol";
import { ENSRegistry } from "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract PublicZkEmailRegistrar is ZkEmailRegistrar {
    constructor(bytes32 rootNode, address verifier, address ens) ZkEmailRegistrar(rootNode, verifier, ens) { }

    function claim(string[] memory domainParts, address owner) public {
        _claim(domainParts, owner);
    }
}

contract MockResolver {
    function approve(bytes32, address, bool) public {
        // no-op
    }
}

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
    PublicZkEmailRegistrar public registrar;
    ENSRegistry public ens;

    function setUp() public {
        verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));

        // setup ENS registry
        vm.startPrank(owner);
        ens = new ENSRegistry();
        ens.setSubnodeOwner(ROOT_NODE, keccak256(bytes("eth")), owner);
        vm.stopPrank();

        registrar = new PublicZkEmailRegistrar(ZKEMAIL_NODE, address(verifier), address(ens));

        vm.prank(owner);
        ens.setSubnodeOwner(ETH_NODE, keccak256(bytes("zk")), address(registrar));
    }

    function test_proveAndClaim_passesForValidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName = abi.encodePacked(bytes(command.email), bytes(".zk.eth"));
        bytes32 expectedNode = _nameHash(expectedEnsName, 0);

        // check that the node is not owned by anyone
        address ownerBefore = ens.owner(expectedNode);
        address ownerBeforeInRegistrar = registrar.owner(expectedNode);
        assertEq(ownerBefore, address(0));
        assertEq(ownerBeforeInRegistrar, address(0));

        registrar.proveAndClaim(command);

        // check ownership has been set in both ENS and registrar correctly
        address ownerAfter = ens.owner(expectedNode);
        address ownerAfterInRegistrar = registrar.owner(expectedNode);
        assertEq(ownerAfter, address(registrar));
        assertEq(ownerAfterInRegistrar, command.owner);
    }

    function test_proveAndClaim_preventsDoubleUseOfNullifier() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        registrar.proveAndClaim(command); // passes the first time
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.NullifierUsed.selector));
        registrar.proveAndClaim(command); // fails the second time
    }

    function test_setRecord_revertsForNonOwner() public {
        bytes32 node = _nameHash(abi.encodePacked(bytes("zk.eth")), 0);
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.NotOwner.selector));
        registrar.setRecord(node, owner, address(0), 0);
    }

    function test_setRecord_setsRecordCorrectlyIfOwner() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        bytes memory expectedEnsName = abi.encodePacked(bytes(command.email), bytes(".zk.eth"));
        bytes32 expectedNode = _nameHash(expectedEnsName, 0);
        registrar.proveAndClaim(command);

        address resolverBefore = ens.resolver(expectedNode);
        assertEq(resolverBefore, address(0));

        address resolver = address(new MockResolver());
        address newOwner = makeAddr("newOwner");
        vm.prank(command.owner);
        registrar.setRecord(expectedNode, newOwner, resolver, 0);

        // check that the record has been set correctly
        address ownerAfter = ens.owner(expectedNode); // should still be registrar
        address ownerAfterInRegistrar = registrar.owner(expectedNode);
        assertEq(ownerAfter, address(registrar));
        assertEq(ownerAfterInRegistrar, newOwner);
    }

    function test_proveAndClaim_revertsForInvalidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        command.email = "bob@example.com";
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.InvalidCommand.selector));
        registrar.proveAndClaim(command);
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
        bytes memory nameBytes = "thezdev3.gmail.com.zk.eth";
        bytes32 expectedHash = 0x62907bb39b3053cafa99c539f1c1d2d2f4d2c62c49a8427a0832a30ef2067f67;
        bytes32 actualHash = _nameHash(nameBytes, 0);
        assertEq(actualHash, expectedHash);
    }

    function _nameHash(bytes memory name, uint256 offset) internal pure returns (bytes32) {
        uint256 atSignIndex = name.indexOf(0x40);
        if (atSignIndex != type(uint256).max) {
            name[atSignIndex] = bytes1(".");
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
