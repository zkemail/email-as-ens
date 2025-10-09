// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { ZkEmailRegistrar } from "../../../src/ZkEmailRegistrar.sol";
import { IVerifier } from "../../../src/interfaces/IVerifier.sol";

contract EncodeTest is Test {
    ZkEmailRegistrar public registrar;
    address public verifier;

    function setUp() public {
        verifier = makeAddr("verifier");
        registrar = new ZkEmailRegistrar(keccak256("rootNode"), verifier, makeAddr("ens"));
    }

    function test_callsVerifierEncode() public {
        bytes memory proof = abi.encode("proof");
        bytes32[] memory publicInputs = new bytes32[](0);
        bytes memory encodedData = bytes("encodedData");

        bytes memory calldataBytes = abi.encodeCall(IVerifier.encode, (proof, publicInputs));
        bytes memory returnDataBytes = abi.encode(encodedData);

        vm.mockCall(verifier, calldataBytes, returnDataBytes);
        vm.expectCall(verifier, calldataBytes);
        registrar.encode(proof, publicInputs);
    }

    function test_returnsCorrectData() public {
        bytes memory proof = abi.encode("proof");
        bytes32[] memory publicInputs = new bytes32[](0);
        bytes memory encodedData = bytes("encodedData");

        bytes memory calldataBytes = abi.encodeCall(IVerifier.encode, (proof, publicInputs));
        bytes memory returnDataBytes = abi.encode(encodedData);

        vm.mockCall(verifier, calldataBytes, returnDataBytes);
        bytes memory result = registrar.encode(proof, publicInputs);
        assertEq(result, encodedData);
    }
}
