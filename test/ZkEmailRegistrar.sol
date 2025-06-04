// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { TestFixtures } from "./fixtures/TestFixtures.sol";
import { ProveAndClaimCommand, ProveAndClaimCommandVerifier } from "../src/utils/Verifier.sol";
import { Groth16Verifier } from "./fixtures/Groth16Verifier.sol";
import { ZkEmailRegistrar } from "../src/ZkEmailRegistrar.sol";

contract PublicZkEmailRegistrar is ZkEmailRegistrar {
    constructor(bytes32 rootNode, address verifier) ZkEmailRegistrar(rootNode, verifier) { }

    function nameHash(bytes memory nameBytes, uint256 offset) public pure returns (bytes32, bytes32) {
        return _nameHash(nameBytes, offset);
    }
}

contract ZkEmailRegistrarTest is Test {
    // namehash(zk.eth)
    // the emails will be claimed as follows: e@d.com.zk.eth
    bytes32 public constant ROOT_NODE = 0xc415680e10d4f52260859f9d558b33c0bd5d28ec16d9ae046d2695cb7144ee64;

    ProveAndClaimCommandVerifier internal _verifier;
    PublicZkEmailRegistrar internal _registrar;

    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));
        _registrar = new PublicZkEmailRegistrar(ROOT_NODE, address(_verifier));
    }

    function test_proveAndClaim_passesForValidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        _registrar.proveAndClaim(command);
    }

    function test_proveAndClaim_revertsForInvalidCommand() public {
        (ProveAndClaimCommand memory command,) = TestFixtures.claimEnsCommand();
        command.email = "bob@example.com";
        vm.expectRevert(abi.encodeWithSelector(ZkEmailRegistrar.InvalidCommand.selector));
        _registrar.proveAndClaim(command);
    }

    function test_nameHash_returnsCorrectHash() public view {
        bytes memory nameBytes = "wevm.eth";
        bytes32 expectedHash = 0x08c85f2f4059e930c45a6aeff9dcd3bd95dc3c5c1cddef6a0626b31152248560;
        bytes32 expectedDomain = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

        (bytes32 actualHash, bytes32 actualDomain) = _registrar.nameHash(bytes(nameBytes), 0);
        assertEq(actualHash, expectedHash);
        assertEq(actualDomain, expectedDomain);
    }
}
