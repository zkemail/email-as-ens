// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Vm } from "forge-std/Vm.sol";
import { LinkXCommand, PubSignals } from "../../src/verifiers/LinkXCommandVerifier.sol";
import { Field, BoundedVec, FieldArray } from "../../src/utils/NoirUtils.sol";

address constant _VM_ADDR = address(uint160(uint256(keccak256("hevm cheat code"))));
Vm constant vm = Vm(_VM_ADDR);

library LinkXTestFixture {
    function linkXCommand() internal view returns (LinkXCommand memory command, bytes32[] memory rawPublicInputs) {
        string memory linkXPath = string.concat(vm.projectRoot(), "/test/fixtures/linkX/");

        rawPublicInputs = _getRawPublicInputs(linkXPath);

        uint256 offset = 3;

        uint256 proverAddressLen = 1;
        FieldArray memory proverAddress =
            FieldArray({ elements: new Field[](proverAddressLen), length: proverAddressLen });
        for (uint256 i = 0; i < proverAddressLen; i++) {
            proverAddress.elements[i] = Field.wrap(rawPublicInputs[i + offset]);
        }
        offset += proverAddressLen;

        uint256 maskedCommandLen = 20;
        FieldArray memory maskedCommand =
            FieldArray({ elements: new Field[](maskedCommandLen), length: maskedCommandLen });
        for (uint256 i = 0; i < maskedCommandLen; i++) {
            maskedCommand.elements[i] = Field.wrap(rawPublicInputs[i + offset]);
        }
        offset += maskedCommandLen;

        uint256 xHandleCapture1Len = uint256(rawPublicInputs[rawPublicInputs.length - 1]);
        Field[] memory xHandleCapture1Elements = new Field[](xHandleCapture1Len);
        for (uint256 i = 0; i < xHandleCapture1Len; i++) {
            xHandleCapture1Elements[i] = Field.wrap(rawPublicInputs[i + offset]);
        }
        offset += xHandleCapture1Len;

        PubSignals memory pubSignals = PubSignals({
            pubkeyHash: Field.wrap(0x25c40dbd781e1a284366b032fe40ab3026e55269cec1694dfe64239c88fdbb5c),
            headerHash0: Field.wrap(0x0000000000000000000000000000000085fb869a94511ccbaaf108f91f59b407),
            headerHash1: Field.wrap(0x00000000000000000000000000000000f36f89025341ed6536cbe2d0d338b7a1),
            proverAddress: proverAddress,
            maskedCommand: maskedCommand, // Link thezdev1 x handle to zkfriendly.eth
            xHandleCapture1: BoundedVec({ elements: xHandleCapture1Elements, maxLength: 64 })
        });

        command = LinkXCommand({
            xHandle: "thezdev1",
            ensName: "zkfriendly.eth",
            proof: _getRawProof(linkXPath),
            pubSignals: pubSignals
        });

        return (command, rawPublicInputs);
    }

    function _getRawProof(string memory dirPath) private view returns (bytes memory proof) {
        bytes memory proofFieldsData = vm.parseJson(vm.readFile(string.concat(dirPath, "proof_fields.json")), ".");
        // proofFieldsData is in strict encoding mode (has head parts at the beginning)
        // we need the non-standard packed mode (no head parts) for the proof
        // thus we decode the data and then encode it again in packed mode
        return abi.encodePacked(abi.decode(proofFieldsData, (bytes32[])));
    }

    function _getRawPublicInputs(string memory dirPath) private view returns (bytes32[] memory publicInputs) {
        bytes memory publicInputsFieldsData =
            vm.parseJson(vm.readFile(string.concat(dirPath, "public_inputs_fields.json")), ".");
        return abi.decode(publicInputsFieldsData, (bytes32[]));
    }
}
