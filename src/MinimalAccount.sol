// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MinimalAccount
 * @notice A minimal account contract that allows for the execution of transactions with a single operator
 * @dev This contract is intended to be used as a minimal account for the ZkEmail platform
 */
contract MinimalAccount is Ownable {
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

    constructor(address owner) Ownable(owner) { }

    receive() external payable { }

    function execute(address to, uint256 value, bytes memory data) external onlyOperator returns (bytes memory) {
        (bool success, bytes memory result) = to.call{ value: value }(data);
        if (!success) revert ExecutionFailed();
        return result;
    }

    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
    }
}
