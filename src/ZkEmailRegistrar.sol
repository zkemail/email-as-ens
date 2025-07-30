// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "./verifiers/ProveAndClaimCommandVerifier.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { EnsUtils } from "./utils/EnsUtils.sol";
import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import { Bytes } from "@openzeppelin/contracts/utils/Bytes.sol";
import { IEntryPoint } from "./interfaces/IEntryPoint.sol";
import { IResolver } from "./interfaces/IResolver.sol";
/**
 * @title ZkEmailRegistrar
 * @notice A contract for registering email-based ENS names
 */

contract ZkEmailRegistrar is IEntryPoint {
    using Bytes for bytes;
    using EnsUtils for bytes;

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
     * @inheritdoc IEntryPoint
     * @dev Specifically decodes data as ProveAndClaimCommand, validates proof and nullifier,
     *      claims the corresponding ENS name for the owner, and sets the resolver records.
     */
    function entrypoint(bytes memory data) external {
        ProveAndClaimCommand memory command = abi.decode(data, (ProveAndClaimCommand));
        _validate(command);

        bytes32 node = _claim(command.emailParts, command.owner);
        // set the record and approve the resolver for the node
        address resolver = _resolveName(command.resolver);
        _setRecord(node, command.owner, resolver, 0);
        IResolver(resolver).setAddr(node, command.owner);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Delegates encoding to the configured VERIFIER contract
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

    function _validate(ProveAndClaimCommand memory command) internal {
        bytes32 emailNullifier = command.proof.fields.emailNullifier;
        if (_isUsed[emailNullifier]) {
            revert NullifierUsed();
        }
        _isUsed[emailNullifier] = true;

        if (!IVerifier(VERIFIER).verify(abi.encode(command))) {
            revert InvalidCommand();
        }
    }

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

    function _setRecord(bytes32 node, address newOwner, address resolver, uint64 ttl) internal {
        address previousOwner = owner[node];
        owner[node] = newOwner;
        emit RecordSet(node, newOwner, resolver, ttl);

        ENS(REGISTRY).setRecord(node, address(this), resolver, ttl);
        IResolver(resolver).approve(node, previousOwner, false);
        IResolver(resolver).approve(node, newOwner, true);
    }

    function _resolveName(string memory name) internal view returns (address) {
        bytes32 node = bytes(name).namehash();
        address resolver = ENS(REGISTRY).resolver(node);

        if (resolver == address(0)) {
            revert ResolverNotFound();
        }

        // TODO: check if the resolver has expected interface

        return IResolver(resolver).addr(node);
    }
}
