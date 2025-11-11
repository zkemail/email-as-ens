// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MinimalAccount
 * @notice A minimal account contract that allows for the execution of transactions with a single operator
 * @dev This contract is intended to be used as a minimal account for the ens <-> zkemail integration
 */
contract MinimalAccount is OwnableUpgradeable {
    bytes32 public ensNode; // namehash(ensName)
    address public operator;

    event OperatorSet(address indexed operator);

    error NotOperator();
    error ExecutionFailed();

    modifier onlyOperator() {
        if (msg.sender != operator) {
            revert NotOperator();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable { }

    function initialize(address owner, bytes32 node) external initializer {
        __Ownable_init(owner);
        ensNode = node;
    }

    function execute(address to, uint256 value, bytes memory data) external onlyOperator returns (bytes memory) {
        (bool success, bytes memory result) = to.call{ value: value }(data);
        if (!success) revert ExecutionFailed();
        return result;
    }

    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit OperatorSet(newOperator);
    }
}
