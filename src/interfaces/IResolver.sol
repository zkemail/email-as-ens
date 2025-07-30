// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IResolver {
    /// @dev Approve a delegate to be able to updated records on a node.
    function approve(bytes32 node, address delegate, bool approved) external;
    /// @dev Set the address for a node.
    function setAddr(bytes32 node, address addr) external;
    /// @dev Get the address for a node.
    function addr(bytes32 node) external view returns (address);
}
