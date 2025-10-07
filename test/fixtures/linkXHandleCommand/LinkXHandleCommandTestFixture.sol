// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Vm } from "forge-std/Vm.sol";
import { LinkXHandleCommand, PublicInputs } from "../../../src/verifiers/LinkXHandleCommandVerifier.sol";
import { TextRecord } from "../../../src/LinkTextRecordVerifier.sol";

address constant _VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));
Vm constant vm = Vm(_VM_ADDR);

library LinkXHandleCommandTestFixture {
    function getFixture() internal view returns (LinkXHandleCommand memory command, bytes32[] memory publicInputs) {
        string memory path = string.concat(vm.projectRoot(), "/test/fixtures/linkXHandleCommand/");

        command = LinkXHandleCommand({
            textRecord: TextRecord({
                ensName: "zkfriendly.eth",
                value: "thezdev1",
                nullifier: 0x85fb869a94511ccbaaf108f91f59b407f36f89025341ed6536cbe2d0d338b7a1
            }),
            proof: abi.encodePacked(_getProofFieldsFromBinary(string.concat(path, "circuit/target/proof"))),
            publicInputs: _getExpectedPublicInputs(string.concat(path, "files/expected_public_inputs.json"))
        });

        return (command, _getPublicInputsFieldsFromBinary(string.concat(path, "circuit/target/public_inputs")));
    }

    /**
     * @notice Reads the expected pub signals from a `expected_public_inputs.json` file (PublicInputs struct object)
     * @param path Path to the file  with the expected public inputs
     * @return publicInputs The PublicInputs struct object
     */
    function _getExpectedPublicInputs(string memory path) private view returns (PublicInputs memory publicInputs) {
        string memory publicInputsFile = vm.readFile(path);
        return PublicInputs({
            pubkeyHash: abi.decode(vm.parseJson(publicInputsFile, ".pubkeyHash"), (bytes32)),
            headerHash: abi.decode(vm.parseJson(publicInputsFile, ".headerHash"), (bytes32)),
            proverAddress: abi.decode(vm.parseJson(publicInputsFile, ".proverAddress"), (string)),
            command: abi.decode(vm.parseJson(publicInputsFile, ".command"), (string)),
            xHandleCapture1: abi.decode(vm.parseJson(publicInputsFile, ".xHandleCapture1"), (string)),
            senderDomainCapture1: abi.decode(vm.parseJson(publicInputsFile, ".senderDomainCapture1"), (string)),
            nullifier: abi.decode(vm.parseJson(publicInputsFile, ".nullifier"), (bytes32))
        });
    }

    /**
     * @notice Reads the proof from a `proof_fields.json` file (array of field / bytes32 values)
     * @param path Path to the file with the proof fields
     * @return proofFields The proof fields
     */
    function _getProofFields(string memory path) private view returns (bytes32[] memory proofFields) {
        bytes memory proofFieldsData = vm.parseJson(vm.readFile(path), ".");
        return abi.decode(proofFieldsData, (bytes32[]));
    }

    /**
     * @notice Reads the proof from a `proof` file (raw bytes of the proof)
     * @param path Path to the file with the proof fields
     * @return proofFields The proof fields
     */
    function _getProofFieldsFromBinary(string memory path) private view returns (bytes32[] memory proofFields) {
        // 1) Read the raw bytes
        bytes memory packed = vm.readFileBinary(path);

        // 2) Decode the blob into fixed bytes32[440]
        (bytes32[440] memory proofFixed) = abi.decode(packed, (bytes32[440]));

        // 3) Convert to dynamic bytes32[]
        proofFields = new bytes32[](440);
        for (uint256 i = 0; i < 440; i++) {
            proofFields[i] = proofFixed[i];
        }
        return proofFields;
    }

    /**
     * @notice Reads the public inputs from a `public_inputs_fields.json` file (array of field / bytes32 values)
     * @param path Path to the file with the public inputs fields
     * @return publicInputs The public inputs fields
     */
    function _getPublicInputsFields(string memory path) private view returns (bytes32[] memory publicInputs) {
        bytes memory publicInputsFieldsData = vm.parseJson(vm.readFile(path), ".");
        return abi.decode(publicInputsFieldsData, (bytes32[]));
    }

    /**
     * @notice Reads the public inputs from a `public_inputs_fields.json` file (array of field / bytes32 values)
     * @param path Path to the file with the public inputs fields
     * @return publicInputs The public inputs fields
     */
    function _getPublicInputsFieldsFromBinary(string memory path)
        private
        view
        returns (bytes32[] memory publicInputs)
    {
        // 1) Read the raw bytes
        bytes memory publicInputsFieldsData = vm.readFileBinary(path);

        // 2) Decode the blob into fixed bytes32[154]
        (bytes32[154] memory publicInputsFixed) = abi.decode(publicInputsFieldsData, (bytes32[154]));

        // 3) Convert to dynamic bytes32[]
        publicInputs = new bytes32[](154);
        for (uint256 i = 0; i < 154; i++) {
            publicInputs[i] = publicInputsFixed[i];
        }
        return publicInputs;
    }
}
