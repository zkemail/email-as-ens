// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkTextRecordEntrypoint, TextRecord } from "./LinkTextRecordEntrypoint.sol";
import { LinkHandleCommand } from "../verifiers/HandleVerifier.sol";

/**
 * @title LinkHandleEntrypoint
 * @notice Verifies a LinkHandleCommand and set the mapping of namehash(ensName) to handle.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkHandleEntrypoint is LinkTextRecordEntrypoint {
    constructor(address verifier) LinkTextRecordEntrypoint(verifier, "com.twitter") { }

    /**
     * @inheritdoc LinkTextRecordEntrypoint
     * @dev Specifically decodes data as LinkHandleCommand and returns text record (ensName, handle, nullifier)
     */
    function _extractTextRecord(bytes memory data) internal pure override returns (TextRecord memory) {
        LinkHandleCommand memory command = abi.decode(data, (LinkHandleCommand));

        return command.textRecord;
    }
}
