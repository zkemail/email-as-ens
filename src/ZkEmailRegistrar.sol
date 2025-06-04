// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "./utils/Verifier.sol";
import { ENS as IEns } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

interface IVerifier {
    function isValid(bytes memory data) external view returns (bool);
}

contract ZkEmailRegistrar {
    bytes32 public immutable ROOT_NODE; // e.g. namehash(zk.eth). all emails domains are under this node e@d.com.zk.eth
    address public immutable VERIFIER; // ProveAndClaimCommand Verifier contract address
    address public immutable ENS; // ENS registry contract address

    error InvalidCommand();

    constructor(bytes32 rootNode, address verifier, address ens) {
        ROOT_NODE = rootNode;
        VERIFIER = verifier;
        ENS = ens;
    }

    function proveAndClaim(ProveAndClaimCommand memory command) external {
        if (!IVerifier(VERIFIER).isValid(abi.encode(command))) {
            revert InvalidCommand();
        }

        _claim(command.emailParts, command.owner);
    }

    function _claim(string[] memory domainParts, address owner) internal {
        uint256 lastPartIndex = domainParts.length - 1;
        bytes32 parent = ROOT_NODE;

        while (lastPartIndex > 0) {
            bytes32 labelHash = keccak256(bytes(domainParts[lastPartIndex]));
            IEns(ENS).setSubnodeOwner(parent, labelHash, address(this));
            parent = keccak256(abi.encodePacked(parent, labelHash));
            --lastPartIndex;
        }

        assert(lastPartIndex == 0);

        bytes32 labelHash = keccak256(bytes(domainParts[0]));
        IEns(ENS).setSubnodeOwner(parent, labelHash, owner);
    }
}
