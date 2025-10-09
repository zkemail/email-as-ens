// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { ZkEmailRegistrarHelper } from "./_ZkEmailRegistrarHelper.sol";
import { IVerifier } from "../../../src/interfaces/IVerifier.sol";

contract DkimRegistryAddressTest is Test {
    ZkEmailRegistrarHelper public helper;

    bytes32 public rootNode;
    address public verifier;
    address public ens;

    function setUp() public {
        rootNode = keccak256("rootNode");
        verifier = makeAddr("verifier");
        ens = makeAddr("ens");
        helper = new ZkEmailRegistrarHelper(rootNode, verifier, ens);
    }

    function test_callsVerifierDkimRegistryAddress() public {
        address dkimRegistry = makeAddr("dkimRegistry");

        bytes memory calldataBytes = abi.encodeCall(IVerifier.dkimRegistryAddress, ());
        bytes memory returnDataBytes = abi.encode(dkimRegistry);

        vm.mockCall(verifier, calldataBytes, returnDataBytes);
        vm.expectCall(verifier, calldataBytes);
        helper.dkimRegistryAddress();
    }

    function test_returnsCorrectAddress() public {
        address dkimRegistry = makeAddr("dkimRegistry");

        bytes memory calldataBytes = abi.encodeCall(IVerifier.dkimRegistryAddress, ());
        bytes memory returnDataBytes = abi.encode(dkimRegistry);

        vm.mockCall(verifier, calldataBytes, returnDataBytes);
        address result = helper.dkimRegistryAddress();
        assertEq(result, dkimRegistry);
    }
}
