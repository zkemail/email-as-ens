// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "./verifiers/ProveAndClaimCommandVerifier.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";

interface IVerifier {
    function isValid(bytes memory data) external view returns (bool);
    function encode(uint256[] memory publicSignals, bytes memory proof) external pure returns (bytes memory);
}

interface IResolver {
    /// @dev Approve a delegate to be able to updated records on a node.
    function approve(bytes32 node, address delegate, bool approved) external;
    /// @dev Set the address for a node.
    function setAddr(bytes32 node, address addr) external;
    /// @dev Get the address for a node.
    function addr(bytes32 node) external view returns (address);
}

/**
 * @title ZkEmailRegistrar
 * @notice A contract for registering email-based ENS names
 */
contract ZkEmailRegistrar {
    using Bytes for bytes;

    bytes32 public immutable ROOT_NODE; // e.g. namehash(zk.eth). all emails domains are under this node e$d.com.zk.eth
    address public immutable VERIFIER; // ProveAndClaimCommand Verifier contract address
    address public immutable REGISTRY; // ENS registry contract address

    mapping(bytes32 node => address owner) public owner;
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event Claimed(bytes32 indexed node, address indexed owner);
    event RecordSet(bytes32 indexed node, address indexed newOwner, address indexed resolver, uint64 ttl);

    error InvalidCommand();
    error NullifierUsed();
    error NotOwner();
    error ResolverNotFound();

    modifier onlyOwner(bytes32 node) {
        if (owner[node] != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    constructor(bytes32 rootNode, address verifier, address registry) {
        ROOT_NODE = rootNode;
        VERIFIER = verifier;
        REGISTRY = registry;
    }

    /**
     * @notice Proves and claims an email-based ENS name, optionally setting a resolver.
     * @param data The ABI-encoded ProveAndClaimCommand struct.
     * @dev This is the main entrypoint for the registrar, typically called by a relayer.
     *      The `data` parameter is constructed off-chain by calling `encode()` with the
     *      ZK proof's public signals and the proof itself. This function verifies the proof,
     *      claims the corresponding ENS name for the owner, and if a resolver is provided
     *      in the command, it sets the resolver records.
     */
    function entrypoint(bytes memory data) external {
        ProveAndClaimCommand memory command = abi.decode(data, (ProveAndClaimCommand));
        bytes32 node = _proveAndClaim(command);
        // set the record and approve the resolver for the node
        address resolver = _resolveName(command.resolver);
        _setRecord(node, command.owner, resolver, 0);
        IResolver(resolver).setAddr(node, command.owner);
    }

    /**
     * @notice Encodes public signals and a ZK proof into the `ProveAndClaimCommand` format.
     * @param publicSignals The public signals from the ZK proof.
     * @param proof The ZK proof bytes (e.g., from a Groth16 prover).
     * @return The ABI-encoded `ProveAndClaimCommand` struct.
     * @dev This function is a convenience wrapper around the verifier's `encode` function.
     *      It allows off-chain services (like a relayer) to construct the data payload
     *      required by the `entrypoint` function without coupling to the verifier's internal
     *      encoding logic.
     */
    function encode(uint256[] memory publicSignals, bytes memory proof) external view returns (bytes memory) {
        return IVerifier(VERIFIER).encode(publicSignals, proof);
    }

    /**
     * @notice Sets the record for an ENS name (only callable by the owner of the node)
     * @param node The node to set the record for
     * @param newOwner The new owner of the node
     * @param resolver The resolver for the node
     * @param ttl The TTL for the node
     */
    function setRecord(bytes32 node, address newOwner, address resolver, uint64 ttl) public onlyOwner(node) {
        _setRecord(node, newOwner, resolver, ttl);
    }

    /**
     * @notice Proves and claims an email-based ENS name
     * @param command The command to prove and claim
     */
    function _proveAndClaim(ProveAndClaimCommand memory command) internal returns (bytes32) {
        bytes32 emailNullifier = command.proof.fields.emailNullifier;
        if (_isUsed[emailNullifier]) {
            revert NullifierUsed();
        }
        _isUsed[emailNullifier] = true;

        if (!IVerifier(VERIFIER).isValid(abi.encode(command))) {
            revert InvalidCommand();
        }

        return _claim(command.emailParts, command.owner);
    }

    /**
     * @notice Claims a node for an email domain
     * @param domainParts The parts of the email domain
     * @param newOwner The new owner of the node
     * @return The node that was claimed
     */
    function _claim(string[] memory domainParts, address newOwner) internal returns (bytes32) {
        bytes32 parent = ROOT_NODE;

        for (uint256 i = domainParts.length; i > 0; i--) {
            bytes32 labelHash = keccak256(bytes(domainParts[i - 1]));
            ENS(REGISTRY).setSubnodeOwner(parent, labelHash, address(this));
            parent = keccak256(abi.encodePacked(parent, labelHash));
        }

        // parent is now the node corresponding to the full email domain
        owner[parent] = newOwner;
        emit Claimed(parent, newOwner);
        return parent;
    }

    /**
     * @notice Sets the record for an ENS name
     * @param node The node to set the record for
     * @param newOwner The new owner of the node
     * @param resolver The resolver for the node
     * @param ttl The TTL for the node
     */
    function _setRecord(bytes32 node, address newOwner, address resolver, uint64 ttl) internal {
        address previousOwner = owner[node];
        owner[node] = newOwner;
        emit RecordSet(node, newOwner, resolver, ttl);

        ENS(REGISTRY).setRecord(node, address(this), resolver, ttl);
        IResolver(resolver).approve(node, previousOwner, false);
        IResolver(resolver).approve(node, newOwner, true);
    }

    /**
     * @notice Resolves an ENS name to an address
     * @param resolverName The ens name of the resolver
     * @return The address of the resolver
     */
    function _resolveName(string memory resolverName) internal view returns (address) {
        bytes memory name = bytes(resolverName);
        bytes32 node = _nameHash(name, 0);
        address resolver = ENS(REGISTRY).resolver(node);

        if (resolver == address(0)) {
            revert ResolverNotFound();
        }

        return IResolver(resolver).addr(node);
    }

    /**
     * @notice Hashes an ENS name
     * @param name The name to hash
     * @param offset The offset to start hashing from
     * @return The hash of the name
     */
    function _nameHash(bytes memory name, uint256 offset) internal pure returns (bytes32) {
        uint256 len = name.length;

        if (offset >= len) {
            return bytes32(0);
        }

        uint256 labelEnd = Math.min(name.indexOf(0x2E, offset), len);
        bytes memory label = name.slice(offset, labelEnd);
        bytes32 labelHash = keccak256(label);

        // Recursive case: hash of (parent nameHash + current labelHash)
        return keccak256(abi.encodePacked(_nameHash(name, labelEnd + 1), labelHash));
    }
}
