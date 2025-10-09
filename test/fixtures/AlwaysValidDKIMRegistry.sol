// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract AlwaysValidDKIMRegistry is IDKIMRegistry {
    function isKeyHashValid(bytes32, bytes32) external pure override returns (bool) {
        return true;
    }
}
