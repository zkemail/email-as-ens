// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract RevertingContract {
    error AlwaysReverts();

    fallback() external payable {
        revert AlwaysReverts();
    }
}

