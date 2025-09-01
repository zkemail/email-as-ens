// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { console } from "forge-std/console.sol";
import { CircuitUtils } from "@zk-email/contracts/CircuitUtils.sol";
import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";

struct XProof {
    XDecodedFields fields;
    bytes proof;
}

struct XDecodedFields {
    bytes32 pubkeyHash;
    bytes32 headerHash0;
    bytes32 headerHash1;
    string proverAddress;
    string owner;
    string xHandleCapture1;
}

struct LinkXCommand {
    string xHandle;
    string ensName;
    XProof proof;
}

contract LinkXCommandVerifier {
    // #1: pubkey_hash 32 bytes -> 1 field -> idx 0
    uint256 public constant PUBKEY_HASH_OFFSET = 0;
    // #2: header_hash_0 32 bytes -> 1 field -> idx 1
    uint256 public constant HEADER_HASH_0_OFFSET = 1;
    // #3: header_hash_1 32 bytes -> 1 field -> idx 2
    uint256 public constant HEADER_HASH_1_OFFSET = 2;
    // #4: prover_address CEIL(31 bytes / 31 bytes per field) = 1 field -> idx 3
    uint256 public constant PROVER_ADDRESS_OFFSET = 3;
    uint256 public constant PROVER_ADDRESS_SIZE = 31;
    // #5: owner CEIL(93 bytes / 31 bytes per field) = 3 fields -> idx 4-6
    uint256 public constant OWNER_OFFSET = 4;
    uint256 public constant OWNER_SIZE = 93; // 3 * 31 = 93 ????
    // // #6: x_handle_capture 64 fields + 1 field (length) = 65 fields -> idx 7-71
    uint256 public constant X_HANDLE_CAPTURE_1_OFFSET = 7;
    uint256 public constant X_HANDLE_CAPTURE_1_SIZE = 2015; // length 64 * 31 = 1984 + 31 = 2015 ????

    address public immutable HONK_VERIFIER;

    constructor(address _honkVerifier) {
        HONK_VERIFIER = _honkVerifier;
    }

    function verify(bytes memory data) external view returns (bool) {
        return _isValid(abi.decode(data, (LinkXCommand)));
    }

    function encode(
        uint256[] calldata pubSignals,
        bytes calldata proof
    )
        external
        pure
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildLinkXCommand(pubSignals, proof));
    }

    function _isValid(LinkXCommand memory command) internal view returns (bool) {
        return _verifyXProof(command.proof, HONK_VERIFIER);
    }

    function _verifyXProof(XProof memory xProof, address honkVerifier) internal view returns (bool isValid) {
        uint256[72] memory pubSignalsUint256 = _packPubSignals(xProof.fields);

        bytes32[] memory pubSignals = new bytes32[](72);
        for (uint256 i = 0; i < 72; i++) {
            pubSignals[i] = bytes32(pubSignalsUint256[i]);
        }

        // verify the proof
        bool validProof = IHonkVerifier(honkVerifier).verify(xProof.proof, pubSignals);

        return validProof;
    }

    function _packPubSignals(XDecodedFields memory decodedFields)
        internal
        pure
        returns (uint256[72] memory pubSignals)
    {
        uint256[][] memory fields = new uint256[][](6);
        fields[0] = CircuitUtils.packBytes32(decodedFields.pubkeyHash);
        fields[1] = CircuitUtils.packBytes32(decodedFields.headerHash0);
        fields[2] = CircuitUtils.packBytes32(decodedFields.headerHash1);
        fields[3] = CircuitUtils.packString(decodedFields.proverAddress, PROVER_ADDRESS_SIZE);
        fields[4] = CircuitUtils.packString(decodedFields.owner, OWNER_SIZE);
        fields[5] = CircuitUtils.packString(decodedFields.xHandleCapture1, X_HANDLE_CAPTURE_1_SIZE);

        uint256[] memory _pubSignals = CircuitUtils.flattenFields(fields, pubSignals.length);
        for (uint256 i = 0; i < _pubSignals.length; i++) {
            pubSignals[i] = _pubSignals[i];
        }

        return pubSignals;
    }

    function _unpackPubSignals(uint256[] calldata pubSignals)
        internal
        pure
        returns (XDecodedFields memory decodedFields)
    {
        console.log("pubSignals.length", pubSignals.length);

        if (pubSignals.length != 72) revert CircuitUtils.InvalidPubSignalsLength();

        decodedFields.pubkeyHash = CircuitUtils.unpackBytes32(pubSignals, PUBKEY_HASH_OFFSET);
        decodedFields.headerHash0 = CircuitUtils.unpackBytes32(pubSignals, HEADER_HASH_0_OFFSET);
        decodedFields.headerHash1 = CircuitUtils.unpackBytes32(pubSignals, HEADER_HASH_1_OFFSET);
        decodedFields.proverAddress = CircuitUtils.unpackString(pubSignals, PROVER_ADDRESS_OFFSET, PROVER_ADDRESS_SIZE);
        decodedFields.owner = CircuitUtils.unpackString(pubSignals, OWNER_OFFSET, OWNER_SIZE);
        decodedFields.xHandleCapture1 =
            CircuitUtils.unpackString(pubSignals, X_HANDLE_CAPTURE_1_OFFSET, X_HANDLE_CAPTURE_1_SIZE);

        return decodedFields;
    }

    function _buildLinkXCommand(
        uint256[] calldata pubSignals,
        bytes memory proof
    )
        private
        pure
        returns (LinkXCommand memory command)
    {
        XDecodedFields memory decodedFields = _unpackPubSignals(pubSignals);

        return LinkXCommand({ xHandle: "", ensName: "", proof: XProof({ fields: decodedFields, proof: proof }) });
    }
}
