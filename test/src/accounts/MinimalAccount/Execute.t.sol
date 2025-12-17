// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { MinimalAccount } from "../../../../src/accounts/MinimalAccount.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { RevertingContract } from "./RevertingContract.sol";

contract MinimalAccountExecuteTest is Test {
    MinimalAccount internal _account;
    address internal _owner;
    address internal _operator;
    bytes32 internal _ensNode;

    function setUp() public {
        _owner = makeAddr("owner");
        _operator = makeAddr("operator");
        _ensNode = keccak256("test.eth");

        // Deploy implementation and proxy
        MinimalAccount implementation = new MinimalAccount();
        bytes memory initData = abi.encodeWithSelector(MinimalAccount.initialize.selector, _owner, _ensNode);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        _account = MinimalAccount(payable(address(proxy)));

        // Set operator
        vm.prank(_owner);
        _account.setOperator(_operator);
    }

    function test_Execute_SucceedsWhenCalledByOperator() public {
        address target = makeAddr("target");
        vm.deal(address(_account), 1 ether);

        vm.prank(_operator);
        _account.execute(target, 0.5 ether, "");

        assertEq(target.balance, 0.5 ether);
    }

    function test_Execute_RevertsWhenCalledByNonOperator() public {
        address nonOperator = makeAddr("nonOperator");
        address target = makeAddr("target");

        vm.prank(nonOperator);
        vm.expectRevert(MinimalAccount.NotOperator.selector);
        _account.execute(target, 0, "");
    }

    function test_Execute_RevertsWhenCalledByOwner() public {
        address target = makeAddr("target");

        vm.prank(_owner);
        vm.expectRevert(MinimalAccount.NotOperator.selector);
        _account.execute(target, 0, "");
    }

    function test_Execute_RevertsWhenCallFails() public {
        RevertingContract revertingTarget = new RevertingContract();

        vm.prank(_operator);
        vm.expectRevert(MinimalAccount.ExecutionFailed.selector);
        _account.execute(address(revertingTarget), 0, "");
    }
}

