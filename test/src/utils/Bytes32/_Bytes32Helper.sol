// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Bytes32 } from "../../../../src/utils/Bytes32.sol";

contract Bytes32Helper {
    function callSlice(
        bytes32[] memory array,
        uint256 start,
        uint256 end
    )
        external
        pure
        returns (bytes32[] memory)
    {
        return Bytes32.slice(array, start, end);
    }

    function callSplice(
        bytes32[] memory array,
        uint256 start,
        bytes32[] memory elements
    )
        external
        pure
        returns (bytes32[] memory)
    {
        return Bytes32.splice(array, start, elements);
    }
}
