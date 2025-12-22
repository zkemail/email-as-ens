// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { OZAccount } from "../../../../src/accounts/OZAccount.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract OZAccountSetECDSASignerTest is Test {
    OZAccount internal _account;
    address internal _owner;

    function setUp() public {
        _owner = makeAddr("owner");
        _account = new OZAccount(_owner);
    }

    function test_SetECDSASigner_SucceedsWhenCalledByOwner() public {
        address newSigner = makeAddr("newSigner");

        vm.prank(_owner);
        _account.setECDSASigner(newSigner);

        assertEq(_account.signer(), newSigner, "Signer should be updated");
    }

    function test_SetECDSASigner_RevertsWhenCalledByNonOwner() public {
        address nonOwner = makeAddr("nonOwner");
        address newSigner = makeAddr("newSigner");

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        _account.setECDSASigner(newSigner);
    }
}

