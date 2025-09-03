// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

type Field is bytes32;

// BoundedVec<Field, MaxLength>
// Contains a dynamic array of Field elements up to a maximum length
// The last element of the array is the actual length of the elements
// This allows for the storage of a variable-length array of Field elements with a maximum size
// The maxLength is the maximum number of elements that can be stored in the bounded vec
// The elements are the actual elements of the bounded vec
struct BoundedVec {
    Field[] elements;
    uint256 maxLength;
}

library NoirUtils {
    error InvalidPubSignalsLength();

    function encodeField(Field field) internal pure returns (bytes32[] memory packedField) {
        packedField = new bytes32[](1);
        packedField[0] = _encodeField(field);
        return packedField;
    }

    function encodeFieldArray(Field[] memory fields) internal pure returns (bytes32[] memory packedFieldArray) {
        return _encodeFieldArray(fields);
    }

    function encodeBoundedVec(BoundedVec memory boundedVec) internal pure returns (bytes32[] memory packedBoundedVec) {
        return _encodeBoundedVec(boundedVec);
    }

    function decodeField(bytes32[] calldata pubSignals, uint256 startIndex) internal pure returns (Field field) {
        return _decodeField(pubSignals, startIndex);
    }

    function decodeFieldArray(
        bytes32[] calldata pubSignals,
        uint256 startIndex,
        uint256 length
    )
        internal
        pure
        returns (Field[] memory fieldArray)
    {
        return _decodeFieldArray(pubSignals, startIndex, length);
    }

    function decodeBoundedVec(
        bytes32[] calldata pubSignals,
        uint256 startIndex,
        uint256 maxLength
    )
        internal
        pure
        returns (BoundedVec memory boundedVec)
    {
        return _decodeBoundedVec(pubSignals, startIndex, maxLength);
    }

    function flattenArray(bytes32[][] memory inputs, uint256 outLength) internal pure returns (bytes32[] memory out) {
        out = new bytes32[](outLength);
        uint256 k = 0;
        for (uint256 i = 0; i < inputs.length; i++) {
            bytes32[] memory arr = inputs[i];
            for (uint256 j = 0; j < arr.length; j++) {
                if (k >= outLength) revert InvalidPubSignalsLength();
                out[k++] = arr[j];
            }
        }
        if (k != outLength) revert InvalidPubSignalsLength();
        return out;
    }

    function _encodeField(Field field) private pure returns (bytes32 packedField) {
        return Field.unwrap(field);
    }

    function _encodeFieldArray(Field[] memory fields) private pure returns (bytes32[] memory packedFieldArray) {
        bytes32[] memory fieldsBytes = new bytes32[](fields.length);
        for (uint256 i = 0; i < fields.length; i++) {
            fieldsBytes[i] = _encodeField(fields[i]);
        }
        return fieldsBytes;
    }

    function _encodeBoundedVec(BoundedVec memory boundedVec) private pure returns (bytes32[] memory packedBoundedVec) {
        // array size is max length + 1 (for storing the actual length)
        packedBoundedVec = new bytes32[](boundedVec.maxLength + 1);
        // first elements are the bounded vec elements, others are left zeroed out
        for (uint256 i = 0; i < boundedVec.elements.length; i++) {
            packedBoundedVec[i] = _encodeField(boundedVec.elements[i]);
        }
        // last element is the actual length of the bounded vec elements
        packedBoundedVec[packedBoundedVec.length - 1] = bytes32(boundedVec.elements.length);
        return packedBoundedVec;
    }

    function _decodeField(bytes32[] calldata pubSignals, uint256 startIndex) private pure returns (Field field) {
        return Field.wrap(pubSignals[startIndex]);
    }

    function _decodeFieldArray(
        bytes32[] calldata pubSignals,
        uint256 startIndex,
        uint256 length
    )
        private
        pure
        returns (Field[] memory fields)
    {
        fields = new Field[](length);
        for (uint256 i = 0; i < length; i++) {
            fields[i] = _decodeField(pubSignals, startIndex + i);
        }
        return fields;
    }

    function _decodeBoundedVec(
        bytes32[] calldata pubSignals,
        uint256 startIndex,
        uint256 maxLength
    )
        private
        pure
        returns (BoundedVec memory boundedVec)
    {
        // max length is the maximum possible length of the bounded vec
        boundedVec.maxLength = maxLength;
        // last element is the actual length of the bounded vec elements
        uint256 actualLength = uint256(pubSignals[pubSignals.length - 1]);
        // only unpack the elements that are actually present
        boundedVec.elements = _decodeFieldArray(pubSignals, startIndex, actualLength);
        return boundedVec;
    }
}
