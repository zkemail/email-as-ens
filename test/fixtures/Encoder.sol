// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "../../src/utils/Verifier.sol";
import { StringUtils } from "../utils/StringUtils.sol";

interface IVerifier {
    function isValid(ProveAndClaimCommand calldata command) external view returns (bool);
}

contract ProveAndClaimProofEncoder {
    address public immutable VERIFIER;

    constructor(address verifier) {
        VERIFIER = verifier;
    }

    function encode(uint256[] calldata publicSignals, bytes calldata proof) public pure returns (bytes memory) {
        ProveAndClaimCommand memory command;

        uint256[] memory domainFields = new uint256[](9);
        for (uint256 i = 0; i < 9; i++) {
            domainFields[i] = publicSignals[i];
        }
        bytes memory domainBytes = StringUtils.fieldsToBytes(domainFields, 255);
        command.domain = StringUtils.bytesToString(domainBytes);

        command.dkimSignerHash = bytes32(publicSignals[9]);
        command.nullifier = bytes32(publicSignals[10]);
        command.timestamp = publicSignals[11];

        uint256[] memory commandFields = new uint256[](20);
        for (uint256 i = 0; i < 20; i++) {
            commandFields[i] = publicSignals[12 + i];
        }
        bytes memory commandBytes = StringUtils.fieldsToBytes(commandFields, 605);
        string memory commandString = StringUtils.bytesToString(commandBytes);
        command.owner = _parseOwnerFromCommand(commandString);

        command.accountSalt = bytes32(publicSignals[32]);
        command.isCodeEmbedded = publicSignals[33] == 1;

        uint256[17] memory pubkey;
        for (uint256 i = 0; i < 17; i++) {
            pubkey[i] = publicSignals[34 + i];
        }
        command.miscellaneousData = abi.encode(pubkey);

        uint256[] memory emailFields = new uint256[](9);
        for (uint256 i = 0; i < 9; i++) {
            emailFields[i] = publicSignals[51 + i];
        }
        bytes memory emailBytes = StringUtils.fieldsToBytes(emailFields, 256);
        command.email = StringUtils.bytesToString(emailBytes);

        command.emailParts = _getEmailParts(command.email);
        command.proof = proof;

        return abi.encode(command);
    }

    function verify(bytes calldata command) public view returns (bool) {
        ProveAndClaimCommand memory cmd = abi.decode(command, (ProveAndClaimCommand));
        return IVerifier(VERIFIER).isValid(cmd);
    }

    function _parseOwnerFromCommand(string memory commandStr) private pure returns (address) {
        bytes memory commandBytes = bytes(commandStr);
        // "Claim ENS name for address 0x" is 30 bytes long.
        // It should be 28 for "Claim ENS name for address " + "0x" = 30. No, it is "Claim ENS name for address " which
        // is 28. Address starts with 0x.
        // Let's check the prefix "Claim ENS name for address ". Length is 28.
        bytes memory prefix = "Claim ENS name for address ";
        require(commandBytes.length == prefix.length + 42, "Invalid command length");

        bytes memory addressBytes = new bytes(42);
        for (uint256 i = 0; i < 42; i++) {
            addressBytes[i] = commandBytes[prefix.length + i];
        }

        return _parseAddress(string(addressBytes));
    }

    function _parseAddress(string memory addrStr) private pure returns (address) {
        bytes memory addrBytes = bytes(addrStr);
        require(addrBytes.length == 42, "Invalid address string length");
        require(addrBytes[0] == "0" && addrBytes[1] == "x", "Address must start with 0x");

        uint160 a;
        for (uint256 i = 0; i < 20; i++) {
            uint8 b1 = _parseHexChar(addrBytes[2 + i * 2]);
            uint8 b2 = _parseHexChar(addrBytes[2 + i * 2 + 1]);
            a |= uint160(b1 * 16 + b2) << (8 * (19 - i));
        }
        return address(a);
    }

    function _parseHexChar(bytes1 char) private pure returns (uint8) {
        if (char >= "0" && char <= "9") {
            return uint8(char) - uint8(bytes1("0"));
        }
        if (char >= "a" && char <= "f") {
            return 10 + uint8(char) - uint8(bytes1("a"));
        }
        if (char >= "A" && char <= "F") {
            return 10 + uint8(char) - uint8(bytes1("A"));
        }
        revert("Invalid hex character");
    }

    function _getEmailParts(string memory email) private pure returns (string[] memory) {
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
        require(atIndex > 0, "Invalid email: no @ symbol");
        return _splitString(string(modifiedEmail), ".");
    }

    function _splitString(string memory str, bytes1 delimiter) private pure returns (string[] memory) {
        bytes memory strBytes = bytes(str);
        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiter) {
                count++;
            }
        }

        string[] memory parts = new string[](count);
        uint256 lastIndex = 0;
        uint256 partIndex = 0;
        for (uint256 i = 0; i < strBytes.length; i++) {
            if (strBytes[i] == delimiter) {
                bytes memory partBytes = new bytes(i - lastIndex);
                for (uint256 j = 0; j < partBytes.length; j++) {
                    partBytes[j] = strBytes[lastIndex + j];
                }
                parts[partIndex] = string(partBytes);
                lastIndex = i + 1;
                partIndex++;
            }
        }
        bytes memory lastPartBytes = new bytes(strBytes.length - lastIndex);
        for (uint256 i = 0; i < lastPartBytes.length; i++) {
            lastPartBytes[i] = strBytes[lastIndex + i];
        }
        parts[partIndex] = string(lastPartBytes);
        return parts;
    }
}
