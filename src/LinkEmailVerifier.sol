// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkEmailCommand } from "./verifiers/LinkEmailCommandVerifier.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { EnsUtils } from "./utils/EnsUtils.sol";
import { IEntryPoint } from "./interfaces/IEntryPoint.sol";
import { ITextRecordVerifier } from "./interfaces/ITextRecordVerifier.sol";

/**
 * @title LinkEmailVerifier
 * @notice Verifies a LinkEmailCommand and set the mapping of namehash(ensName) to email address.
 * @dev The verifier can be updated via the entrypoint function.
 */
contract LinkEmailVerifier is IEntryPoint, ITextRecordVerifier {
    using EnsUtils for bytes;

    bytes32 private immutable _EMAIL_KEY = keccak256(bytes("email"));

    address public immutable VERIFIER; // link email command verifier

    mapping(bytes32 node => string emailAddress) public emailAddress; // can only be updated via the entrypoint function
        // with a valid command
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event EmailAddressSet(bytes32 indexed node, string emailAddress);

    error InvalidCommand();
    error NullifierUsed();

    constructor(address verifier) {
        VERIFIER = verifier;
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Specifically decodes data as LinkEmailCommand, validates proof and nullifier,
     *      then maps the ENS name hash to the email address
     */
    function entrypoint(bytes memory data) external {
        LinkEmailCommand memory command = abi.decode(data, (LinkEmailCommand));
        _validate(command);

        bytes32 node = bytes(command.ensName).namehash();
        emailAddress[node] = command.email;
        emit EmailAddressSet(node, command.email);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Delegates encoding to the configured VERIFIER contract
     */
    function encode(uint256[] calldata publicSignals, bytes calldata proof) external view returns (bytes memory) {
        return IVerifier(VERIFIER).encode(publicSignals, proof);
    }

    /**
     * @notice Returns the address of the DKIM registry
     * @return The address of the DKIM registry used by the verifier
     */
    function dkimRegistryAddress() external view returns (address) {
        return IVerifier(VERIFIER).DKIM_REGISTRY();
    }

    /**
     * @inheritdoc ITextRecordVerifier
     */
    function verifyTextRecord(bytes32 node, string memory key, string memory value) external view returns (bool) {
        // this verifier only supports email text record
        if (keccak256(bytes(key)) != _EMAIL_KEY) {
            revert UnsupportedKey();
        }
        string memory storedEmail = emailAddress[node];
        return keccak256(bytes(storedEmail)) == keccak256(bytes(value));
    }

    function _validate(LinkEmailCommand memory command) internal {
        bytes32 emailNullifier = command.proof.fields.emailNullifier;
        if (_isUsed[emailNullifier]) {
            revert NullifierUsed();
        }
        _isUsed[emailNullifier] = true;

        if (!IVerifier(VERIFIER).verify(abi.encode(command))) {
            revert InvalidCommand();
        }
    }
}
