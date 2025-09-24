// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { StringUtils } from "@zk-email/email-tx-builder/src/libraries/StringUtils.sol";

library EnsUtils {
    using Bytes for bytes;
    using Strings for string;

    function namehash(bytes memory name) internal pure returns (bytes32) {
        return namehash(name, 0);
    }

    function namehash(bytes memory name, uint256 offset) internal pure returns (bytes32) {
        uint256 atSignIndex = name.indexOf(0x40);
        if (atSignIndex != type(uint256).max) {
            name[atSignIndex] = bytes1("$");
        }

        uint256 len = name.length;

        if (offset >= len) {
            return bytes32(0);
        }

        uint256 labelEnd = Math.min(name.indexOf(0x2E, offset), len);
        bytes memory label = name.slice(offset, labelEnd);
        bytes32 labelHash = keccak256(label);

        // Recursive case: hash of (parent nameHash + current labelHash)
        return keccak256(abi.encodePacked(namehash(name, labelEnd + 1), labelHash));
    }

    /**
     * @notice Packs a public key (as bytes) into field elements
     * @param pubKeyBytes The public key bytes (encoded as bytes32[17])
     * @return fields The packed field elements
     */
    function packPubKey(bytes memory pubKeyBytes) internal pure returns (bytes32[] memory fields) {
        uint256[17] memory pubKeyChunks = abi.decode(pubKeyBytes, (uint256[17]));
        fields = new bytes32[](17);
        for (uint256 i = 0; i < 17; i++) {
            fields[i] = bytes32(pubKeyChunks[i]);
        }
        return fields;
    }

    /**
     * @notice Extracts public key from public inputs fields
     * @param publicInputs Array of public inputs
     * @param startIndex Starting index of public key
     * @return pubKeyBytes The public key bytes
     */
    function unpackPubKey(
        bytes32[] memory publicInputs,
        uint256 startIndex
    )
        internal
        pure
        returns (bytes memory pubKeyBytes)
    {
        uint256[17] memory pubKeyChunks;
        for (uint256 i = 0; i < pubKeyChunks.length; i++) {
            pubKeyChunks[i] = uint256(publicInputs[startIndex + i]);
        }
        pubKeyBytes = abi.encode(pubKeyChunks);
        return pubKeyBytes;
    }

    /**
     * @notice Extracts the parts of an email address, replacing '@' with '$' and splitting by '.'
     * @param email The email address to process
     * @return The parts of the email address as a string array
     */
    function extractEmailParts(string memory email) internal pure returns (string[] memory) {
        bytes memory emailBytes = bytes(email);
        bytes memory modifiedEmail = new bytes(emailBytes.length);
        uint256 atIndex = 0;
        for (uint256 i = 0; i < emailBytes.length; i++) {
            if (emailBytes[i] == "@") {
                modifiedEmail[i] = "$";
                atIndex = i;
            } else {
                modifiedEmail[i] = emailBytes[i];
            }
        }

        return StringUtils.splitString(string(modifiedEmail), ".");
    }

    /**
     * @notice Verifies that the email parts are dot separated and match the claimed email
     * @param emailParts The parts of the email address dot separated
     * @param email The complete email address
     * @return True if the email parts are dot separated and match the claimed email, false otherwise
     */
    function verifyEmailParts(string[] memory emailParts, string memory email) internal pure returns (bool) {
        string memory composedEmail = "";
        for (uint256 i = 0; i < emailParts.length; i++) {
            composedEmail = string.concat(composedEmail, emailParts[i]);
            if (i < emailParts.length - 1) {
                composedEmail = string.concat(composedEmail, ".");
            }
        }

        bytes memory emailBytes = bytes(email);
        bytes memory composedEmailBytes = bytes(composedEmail);

        // Ensure composedEmail and emailBytes have the same length
        if (composedEmailBytes.length != emailBytes.length) {
            return false;
        }

        // check if the email parts are dot separated and match the claimed email
        // note since @ sign is not in ens encoding valid char set, we are arbitrarily replacing it with a $
        for (uint256 i = 0; i < emailBytes.length; i++) {
            bytes1 currentByte = emailBytes[i];
            if (currentByte == "@") {
                if (composedEmailBytes[i] != "$") {
                    return false;
                }
            } else if (currentByte != composedEmailBytes[i]) {
                return false;
            }
        }

        return true;
    }
}
