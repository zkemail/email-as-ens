// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";
import { MinimalAccount } from "../../../../src/accounts/MinimalAccount.sol";

contract DeployedAccountTest is XHandleRegistrarTest {
    function test_HasCorrectOwner() public {
        address accountAddr = _registrar.claimAndWithdraw(_validEncodedCommand);

        MinimalAccount account = MinimalAccount(payable(accountAddr));

        assertEq(account.owner(), address(_registrar), "Registrar should be owner of deployed account");
    }

    function test_HasCorrectOperator() public {
        address accountAddr = _registrar.claimAndWithdraw(_validEncodedCommand);

        MinimalAccount account = MinimalAccount(payable(accountAddr));

        assertEq(account.operator(), address(_registrar), "Registrar should be operator of deployed account");
    }

    function test_HasCorrectEnsNode() public {
        address accountAddr = _registrar.claimAndWithdraw(_validEncodedCommand);

        MinimalAccount account = MinimalAccount(payable(accountAddr));

        assertEq(account.ensNode(), _ensNode, "Account should have correct ENS node");
    }
}

