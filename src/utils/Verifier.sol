// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";

struct ProveAndClaimCommand {
    // e.g gmail.com
    string domain;
    // e.g email@gmail.com
    string email;
    // on-chain owner of email@gmail.com.zk.eth
    address owner;
    // hash of RSA pubkey
    bytes32 dkimSignerHash;
    // used to prevent double use of the command
    bytes32 nullifier;
    // signed timestamp in email header. 0 if not supported (e.g outlook.com dosn't sign timestamp)
    uint256 timestamp;
    // ignored here but needed for zk proof verification
    bytes32 accountSalt;
    // same
    bool isCodeEmbedded;
    // Miscellaneous data field for future compatibility and flexibility.
    // This field can hold any additional data that the verifier implementation might need to parse.
    // For example, it could contain DNSSEC proof data for DNSSEC oracle verification.
    // Alternatively, it could be set to 0x0 if no additional data is required.
    bytes miscellaneousData;
    // zkemail proof of validity of the fields of this struct
    bytes proof;
}

interface IGroth16Verifier {
    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[60] calldata _pubSignals
    )
        external
        view
        returns (bool);
}

contract ProveAndClaimCommandVerifier {
    uint256 public constant Q =
        21_888_242_871_839_275_222_246_405_745_257_275_088_696_311_157_297_823_662_689_037_894_645_226_208_583;
    uint256 public constant DOMAIN_FIELDS = 9;
    uint256 public constant DOMAIN_BYTES = 255;
    uint256 public constant EMAIL_FIELDS = 9;
    uint256 public constant EMAIL_BYTES = 256;
    uint256 public constant COMMAND_FIELDS = 20;
    uint256 public constant COMMAND_BYTES = 605;
    uint256 public constant PUBKEY_FIELDS = 17;

    address public immutable GORTH16_VERIFIER;

    constructor(address _groth16Verifier) {
        GORTH16_VERIFIER = _groth16Verifier;
    }

    function isValid(bytes memory data) external view returns (bool) {
        // decode the data into a ProveAndClaimCommand struct
        ProveAndClaimCommand memory command = abi.decode(data, (ProveAndClaimCommand));

        // decode the proof
        (uint256[2] memory pA, uint256[2][2] memory pB, uint256[2] memory pC) =
            abi.decode(command.proof, (uint256[2], uint256[2][2], uint256[2]));

        // check if all values are less than Q (max value of bn128 curve)
        if (
            !(
                pA[0] < Q && pA[1] < Q && pB[0][0] < Q && pB[0][1] < Q && pB[1][0] < Q && pB[1][1] < Q && pC[0] < Q
                    && pC[1] < Q
            )
        ) {
            return false;
        }

        // build the public signals
        uint256[60] memory pubSignals = _buildPubSignals(command);

        // verify the proof
        return IGroth16Verifier(GORTH16_VERIFIER).verifyProof(pA, pB, pC, pubSignals);
    }

    /**
     * Builds the public signals required for the proof verification.
     *
     * The expected public signals are (in order to be packed into 60 fields):
     * - domain_name: 9 fields
     * - public_key_hash: 1 field
     * - email_nullifier: 1 field
     * - timestamp: 1 field
     * - masked_command: 20 fields
     * - account_salt: 1 field
     * - is_code_exist: 1 field
     * - pubkey: 17 fields
     * - email_address: 9 fields
     *
     * @param command The ProveAndClaimCommand struct containing the necessary data.
     * @return An array of 60 uint256 values representing the public signals.
     */
    function _buildPubSignals(ProveAndClaimCommand memory command) internal pure returns (uint256[60] memory) {
        uint256[60] memory pubSignals;

        uint256[] memory domainFields = _packBytes2Fields(bytes(command.domain), DOMAIN_BYTES);
        uint256[] memory emailFields = _packBytes2Fields(bytes(command.email), EMAIL_BYTES);
        uint256[] memory commandFields = _packBytes2Fields(_getExpectedCommand(command.owner), COMMAND_BYTES);
        uint256[PUBKEY_FIELDS] memory pubKeyFields = abi.decode(command.miscellaneousData, (uint256[17]));

        // domain_name
        for (uint256 i = 0; i < DOMAIN_FIELDS; i++) {
            pubSignals[i] = domainFields[i];
        }
        // public_key_hash
        pubSignals[DOMAIN_FIELDS] = uint256(command.dkimSignerHash);
        // email_nullifier
        pubSignals[DOMAIN_FIELDS + 1] = uint256(command.nullifier);
        // timestamp
        pubSignals[DOMAIN_FIELDS + 2] = uint256(command.timestamp);
        // masked_command
        for (uint256 i = 0; i < COMMAND_FIELDS; i++) {
            pubSignals[DOMAIN_FIELDS + 3 + i] = commandFields[i];
        }
        // account_salt
        pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS] = uint256(command.accountSalt);
        // is_code_exist
        pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS + 1] = command.isCodeEmbedded ? 1 : 0;
        // pubkey
        for (uint256 i = 0; i < PUBKEY_FIELDS; i++) {
            pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS + 2 + i] = pubKeyFields[i];
        }
        // email_address
        for (uint256 i = 0; i < EMAIL_FIELDS; i++) {
            pubSignals[DOMAIN_FIELDS + 3 + COMMAND_FIELDS + 2 + PUBKEY_FIELDS + i] = emailFields[i];
        }

        return pubSignals;
    }

    function _packBytes2Fields(bytes memory _bytes, uint256 _paddedSize) internal pure returns (uint256[] memory) {
        uint256 remain = _paddedSize % 31;
        uint256 numFields = (_paddedSize - remain) / 31;
        if (remain > 0) {
            numFields += 1;
        }
        uint256[] memory fields = new uint256[](numFields);
        uint256 idx = 0;
        uint256 byteVal = 0;
        for (uint256 i = 0; i < numFields; i++) {
            for (uint256 j = 0; j < 31; j++) {
                idx = i * 31 + j;
                if (idx >= _paddedSize) {
                    break;
                }
                if (idx >= _bytes.length) {
                    byteVal = 0;
                } else {
                    byteVal = uint256(uint8(_bytes[idx]));
                }
                if (j == 0) {
                    fields[i] = byteVal;
                } else {
                    fields[i] += (byteVal << (8 * j));
                }
            }
        }
        return fields;
    }

    function _getExpectedCommand(address _owner) internal pure returns (bytes memory) {
        string[] memory template = new string[](6);
        template[0] = "Claim";
        template[1] = "ENS";
        template[2] = "name";
        template[3] = "for";
        template[4] = "address";
        template[5] = CommandUtils.ETH_ADDR_MATCHER;
        bytes[] memory commandParams = new bytes[](1);
        commandParams[0] = abi.encode(_owner);
        return bytes(CommandUtils.computeExpectedCommand(commandParams, template, 0));
    }
}
