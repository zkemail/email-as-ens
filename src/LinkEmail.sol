// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { LinkEmailCommand } from "./verifiers/LinkEmailCommandVerifier.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";

contract LinkEmail {
    address public immutable VERIFIER;

    mapping(bytes32 node => string emailAddress) public link;
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event Linked(bytes32 indexed node, string emailAddress);

    error InvalidCommand();
    error NullifierUsed();

    constructor(address verifier) {
        VERIFIER = verifier;
    }

    function entrypoint(bytes memory data) external {
        LinkEmailCommand memory command = abi.decode(data, (LinkEmailCommand));
        _validate(command);
    }

    function encode(
        uint256[] calldata pubSignals,
        bytes calldata proof
    )
        external
        view
        returns (bytes memory encodedCommand)
    {
        return IVerifier(VERIFIER).encode(pubSignals, proof);
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
