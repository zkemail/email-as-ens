// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { ZkEmailRegistrar } from "../../../src/ZkEmailRegistrar.sol";
import { IVerifier } from "../../../src/interfaces/IVerifier.sol";

contract DkimRegistryAddressTest is Test {
    ZkEmailRegistrar public registrar;
    address public verifier;

    function setUp() public {
        verifier = makeAddr("verifier");
        registrar = new ZkEmailRegistrar(keccak256("rootNode"), verifier, makeAddr("ens"));
    }

    function test_callsVerifierDkimRegistryAddress() public {
        address dkimRegistry = makeAddr("dkimRegistry");

        bytes memory calldataBytes = abi.encodeCall(IVerifier.dkimRegistryAddress, ());
        bytes memory returnDataBytes = abi.encode(dkimRegistry);

        vm.mockCall(verifier, calldataBytes, returnDataBytes);
        vm.expectCall(verifier, calldataBytes);
        registrar.dkimRegistryAddress();
    }

    function test_returnsCorrectAddress() public {
        address dkimRegistryAddress = makeAddr("dkimRegistry");

        bytes memory calldataBytes = abi.encodeCall(IVerifier.dkimRegistryAddress, ());
        bytes memory returnDataBytes = abi.encode(dkimRegistryAddress);

        vm.mockCall(verifier, calldataBytes, returnDataBytes);
        address result = registrar.dkimRegistryAddress();
        assertEq(result, dkimRegistryAddress);
    }
}
