// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkTextRecordVerifier } from "./LinkTextRecordVerifier.sol";
import { LinkXHandleCommand } from "./verifiers/LinkXHandleCommandVerifier.sol";

/**
 * @title LinkXHandleVerifier
 * @notice Verifies a LinkXHandleCommand and set the mapping of namehash(ensName) to x handle.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkXHandleVerifier is LinkTextRecordVerifier {
    constructor(address verifier) LinkTextRecordVerifier(verifier, "com.twitter") { }

    /**
     * @inheritdoc LinkTextRecordVerifier
     * @dev Specifically decodes data as LinkXHandleCommand and returns text record (ensName, xHandle, nullifier)
     */
    function _extractTextRecord(bytes memory data) internal pure override returns (TextRecord memory) {
        LinkXHandleCommand memory command = abi.decode(data, (LinkXHandleCommand));

        return TextRecord({ ensName: command.ensName, value: command.xHandle, nullifier: bytes32(0) });
    }
}
