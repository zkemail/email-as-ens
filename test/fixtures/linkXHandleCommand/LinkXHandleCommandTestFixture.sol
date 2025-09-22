// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Vm } from "forge-std/Vm.sol";
import { LinkXHandleCommand, PubSignals } from "../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { TextRecord } from "../../../src/LinkTextRecordVerifier.sol";

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
            textRecord: TextRecord({
                ensName: "zkfriendly.eth",
                value: "thezdev1",
                nullifier: 0x85fb869a94511ccbaaf108f91f59b407f36f89025341ed6536cbe2d0d338b7a1
            }),
            proofFields: _getProofFields(path),
            pubSignals: _getExpectedPubSignals(path)
        });

        return (command, _getPublicInputsFields(path));
    }

    /**
     * @notice Reads the expected pub signals from a `expected_pub_signals.json` file (PubSignals struct object)
     * @param dirPath Path to the directory containing the `expected_pub_signals.json` file
     * @return pubSignals The PubSignals struct object
     */
    function _getExpectedPubSignals(string memory dirPath) private view returns (PubSignals memory pubSignals) {
        string memory pubSignalsFile = vm.readFile(string.concat(dirPath, "expected_pub_signals.json"));
        return PubSignals({
            pubkeyHash: abi.decode(vm.parseJson(pubSignalsFile, ".pubkeyHash"), (bytes32)),
            headerHash: abi.decode(vm.parseJson(pubSignalsFile, ".headerHash"), (bytes32)),
            proverAddress: abi.decode(vm.parseJson(pubSignalsFile, ".proverAddress"), (string)),
            command: abi.decode(vm.parseJson(pubSignalsFile, ".command"), (string)),
            xHandleCapture1: abi.decode(vm.parseJson(pubSignalsFile, ".xHandleCapture1"), (string)),
            senderDomainCapture1: abi.decode(vm.parseJson(pubSignalsFile, ".senderDomainCapture1"), (string))
        });
    }

    /**
     * @notice Reads the proof from a `proof_fields.json` file (array of field / bytes32 values)
     * @param dirPath Path to the directory containing the `proof_fields.json` file
     * @return proofFields The proof fields
     */
    function _getProofFields(string memory dirPath) private view returns (bytes32[] memory proofFields) {
        bytes memory proofFieldsData = vm.parseJson(vm.readFile(string.concat(dirPath, "proof_fields.json")), ".");
        return abi.decode(proofFieldsData, (bytes32[]));
    }

    /**
     * @notice Reads the proof from a `proof` file (raw bytes of the proof)
     * @param dirPath Path to the directory containing the `proof` file
     * @return proofFields The proof fields
     */
    function _getProof(string memory dirPath) private view returns (bytes32[] memory proofFields) {
        // 1) Read the raw bytes
        bytes memory packed = vm.readFileBinary(string.concat(dirPath, "proof"));

        // 2) Decode the blob into fixed bytes32[440]
        (bytes32[440] memory proofFixed) = abi.decode(packed, (bytes32[440]));

        // 3) Convert to dynamic bytes32[]
        proofFields = new bytes32[](440);
        for (uint256 i = 0; i < 440; i++) {
            proofFields[i] = proofFixed[i];
        }

        // 4) Return the proof
        return proofFields;
    }

    /**
     * @notice Reads the public inputs from a `public_inputs_fields.json` file (array of field / bytes32 values)
     * @param dirPath Path to the directory containing the `public_inputs_fields.json` file
     * @return publicInputs The public inputs fields
     */
    function _getPublicInputsFields(string memory dirPath) private view returns (bytes32[] memory publicInputs) {
        bytes memory publicInputsFieldsData =
            vm.parseJson(vm.readFile(string.concat(dirPath, "public_inputs_fields.json")), ".");
        return abi.decode(publicInputsFieldsData, (bytes32[]));
    }
}
