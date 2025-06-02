// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "./utils/Verifier.sol";

/**
 * @title ZkEmailRegistrar
 * @notice A contract that enables email address owners to claim corresponding ENS names using zero-knowledge proofs
 * @dev This contract uses ZK-EMAIL to verify email ownership.
 *      It allows users to prove they own an email address (e.g., "user[at]example.com") and claim
 *      the corresponding ENS subdomain (e.g., "user[at]example.com.zk.eth") for any Ethereum address.
 *
 *      The verification process relies on DKIM signatures in emails, which are cryptographically
 *      verified through zero-knowledge proofs to ensure email authenticity while maintaining privacy.
 */
contract ZkEmailRgistrar {
    /// @notice The address of the verifier contract that validates ZK proofs for ProveAndClaimCommand
    /// @dev This verifier ensures that the provided ZK proof correctly demonstrates email ownership
    address public immutable VERIFIER;

    /// @notice The address of the ENS registry contract
    /// @dev Used to interact with the Ethereum Name Service for domain registration and management
    address public immutable ENS;

    /// @notice The node hash representing the top-level domain for email-based ENS names
    /// @dev This represents the parent domain (e.g., ".zk.eth") under which email addresses are registered
    bytes32 public immutable NODE;

    /**
     * @notice Emitted when an ENS name is successfully claimed for an email address
     * @param owner The Ethereum address that now owns the claimed ENS name
     * @param emailAddress The email address that was used to claim the ENS name
     * @dev This event allows off-chain services to track successful ENS claims and build indexes
     */
    event EnsClaimed(address owner, string emailAddress);

    /**
     * @notice Thrown when the provided ZK proof is invalid or verification fails
     * @dev This error occurs when the verifier contract returns false for the provided proof,
     *      indicating that the email ownership could not be cryptographically verified
     */
    error InvalidProof();

    /**
     * @notice Initializes the ZkEmailRegistrar with required contract addresses and configuration
     * @param _verifier The address of the ProveAndClaimCommandVerifier contract
     * @param _ens The address of the ENS registry contract
     * @param _node The node hash representing the TLD for email-based ENS names (e.g., namehash("zk.eth"))
     * @dev All parameters are immutable after deployment to ensure contract integrity and prevent
     *      unauthorized changes to critical infrastructure addresses
     */
    constructor(address _verifier, address _ens, bytes32 _node) {
        VERIFIER = _verifier;
        ENS = _ens;
        NODE = _node;
    }

    /**
     * @notice Enables the owner of an email address to claim the corresponding ENS name for any Ethereum address
     * @dev This allows the owner of "myemail[at]example.com" to claim "myemail[at]example.com.zk.eth" and set
     *      0x1234567890123456789012345678901234567890 as the owner of "myemail[at]example.com.zk.eth".
     *
     *      The zk-email command for claiming an ENS name is structured as follows:
     *      `Claim ENS name for address {ethAddr}`
     *
     *      The function verifies the ZK proof embedded in the command to ensure:
     *      1. The caller owns the email address through DKIM signature verification
     *      2. The email contains the specific command format with the target Ethereum address
     *      3. The proof has not been used before (nullifier check)
     *      4. The email timestamp is valid (if supported by the email provider)
     *
     * @param command The ABI-encoded data compatible with the verifier being used containing the ZK proof and claim
     * details
     * @dev This function's design is inspired by the DNSRegistrar contract from the ENS domains project:
     *      https://github.com/ensdomains/ens-contracts/blob/staging/contracts/dnsregistrar/DNSRegistrar.sol
     *
     *      Requirements:
     *      - The command must contain a valid ZK proof
     *      - The proof must verify against the configured VERIFIER contract
     *      - The nullifier must not have been used before
     *
     *      Emits an {EnsClaimed} event upon successful claim.
     *
     *      Reverts with {InvalidProof} if the ZK proof verification fails.
     */
    function proveAndClaim(bytes memory command) external {
        // TODO: Implement the logic to claim the ENS name
    }

    /**
     * @notice Claims an ENS name and sets a specific resolver and address record
     * @dev Extended version of proveAndClaim that also configures the ENS name with a resolver
     *      and sets the address record in a single transaction. This is more gas-efficient
     *      when the user wants to immediately configure their ENS name.
     *
     * @param command The ABI-encoded data containing the ZK proof and claim details
     * @param resolver The address of the resolver contract to set for the claimed ENS name
     * @param addr The Ethereum address to set as the address record for the claimed ENS name
     *
     * @dev This function performs the same verification as proveAndClaim but additionally:
     *      1. Sets the resolver for the claimed ENS name
     *      2. Configures the address record to point to the specified address
     *
     *      The addr parameter can be different from the owner set in the command, allowing
     *      flexible configuration where ownership and resolution can point to different addresses.
     *
     *      Requirements:
     *      - All requirements from proveAndClaim must be met
     *      - The resolver address must not be zero
     *      - The addr address must not be zero
     *
     *      Emits an {EnsClaimed} event upon successful claim.
     *
     *      Reverts with {InvalidProof} if the ZK proof verification fails.
     */
    function proveAndClaimWithResolver(bytes memory command, address resolver, address addr) external {
        // TODO: check email address matches the provided name
        // TODO: Implement the logic to claim the ENS name
    }
}
