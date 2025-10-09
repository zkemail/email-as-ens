// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkTextRecordEntrypoint, TextRecord } from "./LinkTextRecordEntrypoint.sol";
import { LinkXHandleCommand } from "../verifiers/LinkXHandleCommandVerifier.sol";

/**
 * @title LinkXHandleEntrypoint
 * @notice Verifies a LinkXHandleCommand and set the mapping of namehash(ensName) to x handle.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkXHandleEntrypoint is LinkTextRecordEntrypoint {
    constructor(address verifier) LinkTextRecordEntrypoint(verifier, "com.twitter") { }

    /**
     * @inheritdoc LinkTextRecordEntrypoint
     * @dev Specifically decodes data as LinkXHandleCommand and returns text record (ensName, xHandle, nullifier)
     */
    function _extractTextRecord(bytes memory data) internal pure override returns (TextRecord memory) {
        LinkXHandleCommand memory command = abi.decode(data, (LinkXHandleCommand));

        return command.textRecord;
    }
}
