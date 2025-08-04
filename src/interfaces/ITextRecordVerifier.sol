// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface ITextRecordVerifier {
    error UnsupportedKey();

    /**
     * @notice Verifies the text record for the given node, key and value
     * @param node The node to verify the text record for (namehash of the ENS name)
     * @param key The key of the text record (e.g. "email")
     * @param value The value of the text record (e.g. "test@example.com")
     * @return isValid True if the text record is valid, false otherwise
     */
    function verifyTextRecord(bytes32 node, string memory key, string memory value) external view returns (bool);
}
