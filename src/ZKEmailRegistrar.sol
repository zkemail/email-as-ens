// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { ProveAndClaimCommand } from "./utils/Verifier.sol";

contract ZkEmailRgistrar {
    address public immutable VERIFIER; // verifier that verifies ProveAndClaimCommand zk proof
    address public immutable ENS; // ENS registry
    bytes32 public immutable NODE; // TLD of email based ENS names (e.g .zk.eth)

    // note to reviewer: should we mark anything as indexed? emit other fields ?
    event EnsClaimed(address owner, string emailAddress);

    error InvalidProof();

    constructor(address _verifier, address _ens, bytes32 _node) {
        VERIFIER = _verifier;
        ENS = _ens;
        NODE = _node;
    }

    /// @notice Enables the owner of an email address to claim the corresponding ENS name for any Ethereum address.
    ///         This allows the owner of "myemail[at]example.com" to claim "myemail[at]example.com.zk.eth" and set
    ///         0x1234567890123456789012345678901234567890 as the owner of "myemail[at]example.com.zk.eth".
    ///
    ///         The zk-email command for claiming an ENS name is structured as follows:
    ///         `Claim ENS name for address {ethAddr}`
    ///
    /// @param command The zkemail verified command that proves ownership of the claimed email.
    ///
    /// @dev This function's design is inspired by the DNSRegistrar contract from the ENS domains project:
    /// https://github.com/ensdomains/ens-contracts/blob/staging/contracts/dnsregistrar/DNSRegistrar.sol
    function proveAndClaim(bytes memory command) external {
        // TODO: Implement the logic to claim the ENS name
    }

    function proveAndClaimWithResolver(bytes memory command, address resolver, address addr) external {
        // TODO: check email address matches the provided name
        // TODO: Implement the logic to claim the ENS name
    }
}
