// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Vm } from "forge-std/Vm.sol";
import { LinkXHandleCommand, PubSignals } from "../../../src/verifiers/LinkXHandleCommandVerifier.sol";

address constant _VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));
Vm constant vm = Vm(_VM_ADDR);

library LinkXHandleCommandTestFixture {
    function getFixture()
        internal
        view
        returns (LinkXHandleCommand memory command, bytes32[] memory publicInputsFields)
    {
        string memory path = string.concat(vm.projectRoot(), "/test/fixtures/linkXHandleCommand/files/");

        command = LinkXHandleCommand({
            xHandle: "thezdev1",
            ensName: "zkfriendly.eth",
            proofFields: _getProofFields(path),
            pubSignals: _getExpectedPubSignals(path)
        });

        return (command, _getPublicInputsFields(path));
    }

    function _getExpectedPubSignals(string memory dirPath) private view returns (PubSignals memory pubSignals) {
        string memory pubSignalsFile = vm.readFile(string.concat(dirPath, "expected_pub_signals.json"));
        return PubSignals({
            pubkeyHash: abi.decode(vm.parseJson(pubSignalsFile, ".pubkeyHash"), (bytes32)),
            headerHash0: abi.decode(vm.parseJson(pubSignalsFile, ".headerHash0"), (bytes32)),
            headerHash1: abi.decode(vm.parseJson(pubSignalsFile, ".headerHash1"), (bytes32)),
            proverAddress: abi.decode(vm.parseJson(pubSignalsFile, ".proverAddress"), (string)),
            command: abi.decode(vm.parseJson(pubSignalsFile, ".command"), (string)),
            xHandleCapture1: abi.decode(vm.parseJson(pubSignalsFile, ".xHandleCapture1"), (string)),
            senderDomainCapture1: abi.decode(vm.parseJson(pubSignalsFile, ".senderDomainCapture1"), (string))
        });
    }

    function _getProofFields(string memory dirPath) private view returns (bytes32[] memory proofFields) {
        bytes memory proofFieldsData = vm.parseJson(vm.readFile(string.concat(dirPath, "proof_fields.json")), ".");
        return abi.decode(proofFieldsData, (bytes32[]));
    }

    function _getPublicInputsFields(string memory dirPath) private view returns (bytes32[] memory publicInputs) {
        bytes memory publicInputsFieldsData =
            vm.parseJson(vm.readFile(string.concat(dirPath, "public_inputs_fields.json")), ".");
        return abi.decode(publicInputsFieldsData, (bytes32[]));
    }
}
