// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkTextRecordVerifier } from "./LinkTextRecordVerifier.sol";
import { LinkEmailCommand } from "./verifiers/LinkEmailCommandVerifier.sol";

/**
 * @title LinkEmailVerifier
 * @notice Verifies a LinkEmailCommand and set the mapping of namehash(ensName) to email address.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkEmailVerifier is LinkTextRecordVerifier {
    constructor(address verifier) LinkTextRecordVerifier(verifier, "email") { }

    /**
     * @inheritdoc LinkTextRecordVerifier
     * @dev Specifically decodes data as LinkEmailCommand and returns text record (ensName, emailAddress, nullifier)
     */
    function _extractTextRecord(bytes memory data) internal pure override returns (TextRecord memory) {
        LinkEmailCommand memory command = abi.decode(data, (LinkEmailCommand));

        return TextRecord({
            ensName: command.ensName,
            value: command.email,
            nullifier: command.proof.fields.emailNullifier
        });
    }
}
