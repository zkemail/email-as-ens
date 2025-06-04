// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "./fixtures/TestFixtures.sol";
import { ProveAndClaimCommand, ProveAndClaimCommandVerifier } from "../src/utils/Verifier.sol";
import { Groth16Verifier } from "./fixtures/Groth16Verifier.sol";
import { ZkEmailRegistrar } from "../src/ZkEmailRegistrar.sol";
import { ENSRegistry } from "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import { console } from "forge-std/console.sol";

contract PublicZkEmailRegistrar is ZkEmailRegistrar {
    constructor(bytes32 rootNode, address verifier, address ens) ZkEmailRegistrar(rootNode, verifier, ens) { }

    function nameHash(bytes memory nameBytes, uint256 offset) public pure returns (bytes32, bytes32) {
        return _nameHash(nameBytes, offset);
    }
}

contract ZkEmailRegistrarTest is Test {
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

    function test_setup() public {
        address rootOwner = ens.owner(ROOT_NODE);
        address ethOwner = ens.owner(ETH_NODE);
        address zkOwner = ens.owner(ZKEMAIL_NODE);

        assertEq(rootOwner, owner);
        assertEq(ethOwner, owner);
        assertEq(zkOwner, address(registrar));
    }

    function test_proveAndClaim_passesForValidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        registrar.proveAndClaim(command);
    }

    function test_proveAndClaim_revertsForInvalidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        command.email = "bob@example.com";
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.InvalidCommand.selector));
        registrar.proveAndClaim(command);
    }

    function test_nameHash_returnsCorrectHash() public view {
        bytes memory nameBytes = "wevm.eth";
        bytes32 expectedHash = 0x08c85f2f4059e930c45a6aeff9dcd3bd95dc3c5c1cddef6a0626b31152248560;
        bytes32 expectedDomain = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

        (bytes32 actualHash, bytes32 actualDomain) = registrar.nameHash(bytes(nameBytes), 0);
        assertEq(actualHash, expectedHash);
        assertEq(actualDomain, expectedDomain);
    }
}
