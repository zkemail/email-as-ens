// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Vm } from "forge-std/Vm.sol";
import { LinkXCommand, PubSignals } from "../../src/verifiers/LinkXCommandVerifier.sol";

address constant _VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));
Vm constant vm = Vm(_VM_ADDR);

library LinkXTestFixture {
    function linkXCommand() internal view returns (LinkXCommand memory command, bytes32[] memory publicInputsFields) {
        string memory linkXPath = string.concat(vm.projectRoot(), "/test/fixtures/linkX/");

        publicInputsFields = _getPublicInputsFields(linkXPath);

        PubSignals memory pubSignals = PubSignals({
            pubkeyHash: 0x25c40dbd781e1a284366b032fe40ab3026e55269cec1694dfe64239c88fdbb5c,
            headerHash0: 0x0000000000000000000000000000000085fb869a94511ccbaaf108f91f59b407,
            headerHash1: 0x00000000000000000000000000000000f36f89025341ed6536cbe2d0d338b7a1,
            proverAddress: "",
            command: "Link my x handle to zkfriendly.eth",
            xHandleCapture1: "thezdev1",
            senderDomainCapture1: "x.com"
        });

        command = LinkXCommand({
            xHandle: "thezdev1",
            ensName: "zkfriendly.eth",
            proofFields: _getProofFields(linkXPath),
            pubSignals: pubSignals
        });

        return (command, publicInputsFields);
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
