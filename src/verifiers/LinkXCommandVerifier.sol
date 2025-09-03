// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IHonkVerifier } from "../interfaces/IHonkVerifier.sol";
import { NoirUtils, BoundedVec, Field } from "../utils/NoirUtils.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

struct PubSignals {
    Field pubkeyHash;
    Field headerHash0;
    Field headerHash1;
    Field[] proverAddress;
    Field[] owner;
    BoundedVec xHandleCapture1;
}

struct Command {
    string xHandle;
    string ensName;
    bytes proof;
    PubSignals pubSignals;
}

contract LinkXCommandVerifier {
    // #1: pubkey_hash 32 bytes -> 1 field -> idx 0
    uint256 public constant PUBKEY_HASH_OFFSET = 0;
    uint256 public constant PUBKEY_HASH_LEN = 1;
    // #2: header_hash_0 32 bytes -> 1 field -> idx 1
    uint256 public constant HEADER_HASH_0_OFFSET = 1;
    uint256 public constant HEADER_HASH_0_LEN = 1;
    // #3: header_hash_1 32 bytes -> 1 field -> idx 2
    uint256 public constant HEADER_HASH_1_OFFSET = 2;
    uint256 public constant HEADER_HASH_1_LEN = 1;
    // #4: prover_address CEIL(31 bytes / 31 bytes per field) = 1 field -> idx 3
    uint256 public constant PROVER_ADDRESS_OFFSET = 3;
    uint256 public constant PROVER_ADDRESS_LEN = 1;
    // #5: owner CEIL(93 bytes / 31 bytes per field) = 3 fields -> idx 4-6
    uint256 public constant OWNER_OFFSET = 4;
    uint256 public constant OWNER_LEN = 3;
    // // #6: x_handle_capture 64 fields + 1 field (length) = 65 fields -> idx 7-71
    uint256 public constant X_HANDLE_CAPTURE_1_OFFSET = 7;
    uint256 public constant X_HANDLE_CAPTURE_1_MAX_LEN = 64;

    uint256 public constant PUBLIC_SIGNALS_LENGTH = 72;

    address public immutable HONK_VERIFIER;

    constructor(address _honkVerifier) {
        HONK_VERIFIER = _honkVerifier;
    }

    function verify(bytes memory data) external view returns (bool) {
        Command memory command = abi.decode(data, (Command));

        return IHonkVerifier(HONK_VERIFIER).verify(command.proof, _encodePubSignals(command.pubSignals))
            && Strings.equal(command.ensName, command.ensName)
            && _compareXHandle(command.xHandle, command.pubSignals.xHandleCapture1);
    }

    function encode(
        bytes calldata proof,
        bytes32[] calldata pubSignals
    )
        external
        pure
        returns (bytes memory encodedCommand)
    {
        return abi.encode(_buildCommand(pubSignals, proof));
    }

    function _encodePubSignals(PubSignals memory decodedFields) internal pure returns (bytes32[] memory pubSignals) {
        bytes32[][] memory fields = new bytes32[][](6);
        fields[0] = NoirUtils.encodeField(decodedFields.pubkeyHash);
        fields[1] = NoirUtils.encodeField(decodedFields.headerHash0);
        fields[2] = NoirUtils.encodeField(decodedFields.headerHash1);
        fields[3] = NoirUtils.encodeFieldArray(decodedFields.proverAddress);
        fields[4] = NoirUtils.encodeFieldArray(decodedFields.owner);
        fields[5] = NoirUtils.encodeBoundedVec(decodedFields.xHandleCapture1);

        return NoirUtils.flattenArray(fields, PUBLIC_SIGNALS_LENGTH);
    }

    function _decodePubSignals(bytes32[] calldata encoded) internal pure returns (PubSignals memory decoded) {
        if (encoded.length != PUBLIC_SIGNALS_LENGTH) revert NoirUtils.InvalidPubSignalsLength();

        return PubSignals({
            pubkeyHash: NoirUtils.decodeField(encoded, PUBKEY_HASH_OFFSET),
            headerHash0: NoirUtils.decodeField(encoded, HEADER_HASH_0_OFFSET),
            headerHash1: NoirUtils.decodeField(encoded, HEADER_HASH_1_OFFSET),
            proverAddress: NoirUtils.decodeFieldArray(encoded, PROVER_ADDRESS_OFFSET, PROVER_ADDRESS_LEN),
            owner: NoirUtils.decodeFieldArray(encoded, OWNER_OFFSET, OWNER_LEN),
            xHandleCapture1: NoirUtils.decodeBoundedVec(encoded, X_HANDLE_CAPTURE_1_OFFSET, X_HANDLE_CAPTURE_1_MAX_LEN)
        });
    }

    function _buildCommand(
        bytes32[] calldata encodedPubSignals,
        bytes memory proof
    )
        private
        pure
        returns (Command memory command)
    {
        PubSignals memory pubSignals = _decodePubSignals(encodedPubSignals);
        return Command({
            xHandle: string(abi.encodePacked(pubSignals.xHandleCapture1.elements)),
            ensName: "zkfriendly.eth",
            proof: proof,
            pubSignals: pubSignals
        });
    }

    function _compareXHandle(string memory xHandle, BoundedVec memory xHandleCapture1) private pure returns (bool) {
        string memory xHandleString = string(abi.encodePacked(xHandleCapture1.elements));
        bool res = Strings.equal(xHandle, xHandleString);
        return res;
    }
}
