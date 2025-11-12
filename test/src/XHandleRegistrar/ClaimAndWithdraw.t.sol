// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";
import { XHandleRegistrar } from "../../../src/XHandleRegistrar.sol";
import { ClaimXHandleCommand } from "../../../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { IVerifier } from "../../../src/interfaces/IVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract ClaimAndWithdrawTest is XHandleRegistrarTest {
    event AccountClaimed(
        bytes32 indexed ensNode, address indexed account, address indexed target, uint256 withdrawnAmount
    );

    function test_CanReceiveEthBeforeDeployment() public {
        // Predict the address
        address predictedAddr = _registrar.predictAddress(_ensNode);

        // Send ETH to predicted address before deployment
        uint256 fundAmount = 1 ether;
        vm.deal(predictedAddr, fundAmount);

        assertEq(predictedAddr.balance, fundAmount, "Predicted address should have received ETH");
    }

    function test_DeploysAccountAndWithdrawsEth() public {
        // Pre-fund the predicted address
        address predictedAddr = _registrar.predictAddress(_ensNode);
        uint256 fundAmount = 1 ether;
        vm.deal(predictedAddr, fundAmount);

        // Record initial balance of target
        uint256 targetInitialBalance = _validCommand.target.balance;

        // Expect the AccountClaimed event
        vm.expectEmit(true, true, true, true);
        emit AccountClaimed(_ensNode, predictedAddr, _validCommand.target, fundAmount);

        // Claim and withdraw
        address deployedAccount = _registrar.claimAndWithdraw(_validEncodedCommand);

        // Verify account was deployed at predicted address
        assertEq(deployedAccount, predictedAddr, "Account should be deployed at predicted address");

        // Verify account is stored in mapping
        assertEq(_registrar.getAccount(_ensNode), predictedAddr, "Account should be stored in mapping");

        // Verify ETH was withdrawn to target
        assertEq(_validCommand.target.balance, targetInitialBalance + fundAmount, "should receive withdrawn ETH");

        // Verify account balance is now zero
        assertEq(deployedAccount.balance, 0, "Account balance should be zero after withdrawal");

        // Verify nullifier was marked as used
        assertTrue(
            _registrar.isNullifierUsed(_validCommand.publicInputs.emailNullifier), "Nullifier should be marked as used"
        );
    }

    function test_WorksWithZeroBalance() public {
        // Don't pre-fund the address
        address predictedAddr = _registrar.predictAddress(_ensNode);
        uint256 targetInitialBalance = _validCommand.target.balance;

        // Claim and withdraw
        address deployedAccount = _registrar.claimAndWithdraw(_validEncodedCommand);

        // Verify account was deployed
        assertEq(deployedAccount, predictedAddr, "Account should be deployed at predicted address");

        // Verify no ETH was transferred
        assertEq(_validCommand.target.balance, targetInitialBalance, "Target balance should not change");
    }

    function test_SecondClaimWithDifferentNullifierWorks() public {
        // First claim deploys the account
        _registrar.claimAndWithdraw(_validEncodedCommand);

        // Pre-fund again
        address accountAddr = _registrar.getAccount(_ensNode);
        uint256 secondFundAmount = 0.5 ether;
        vm.deal(accountAddr, secondFundAmount);

        // Get a new command with different nullifier but same handle
        ClaimXHandleCommand memory secondCommand = _validCommand;
        secondCommand.publicInputs.emailNullifier = keccak256("different_nullifier");

        // Mock the verifier to accept this command
        vm.mockCall(address(_verifier), abi.encodeWithSelector(IVerifier.verify.selector), abi.encode(true));

        uint256 targetBalance = _validCommand.target.balance;

        // Second claim should succeed and withdraw
        _registrar.claimAndWithdraw(abi.encode(secondCommand));

        // Verify withdrawal happened
        assertEq(_validCommand.target.balance, targetBalance + secondFundAmount, "Second withdrawal should succeed");
    }

    function test_RevertsWhen_NullifierReused() public {
        // First successful claim
        _registrar.claimAndWithdraw(_validEncodedCommand);

        // Try to claim again with same nullifier
        vm.expectRevert(XHandleRegistrar.NullifierUsed.selector);
        _registrar.claimAndWithdraw(_validEncodedCommand);
    }

    function test_RevertsWhen_InvalidProof() public {
        // Corrupt the proof
        ClaimXHandleCommand memory invalidCommand = _validCommand;
        bytes memory corruptedProof = new bytes(invalidCommand.proof.length);
        corruptedProof[0] = invalidCommand.proof[0] ^ bytes1(uint8(1));
        invalidCommand.proof = corruptedProof;

        // Should revert due to invalid proof
        vm.expectRevert();
        _registrar.claimAndWithdraw(abi.encode(invalidCommand));
    }

    function test_RevertsWhen_InvalidDkimKey() public {
        // Setup a command that will fail DKIM validation
        ClaimXHandleCommand memory invalidCommand = _validCommand;

        // Clear the mock for DKIM registry
        vm.clearMockedCalls();

        // Mock DKIM registry to return false
        vm.mockCall(
            _dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(invalidCommand.publicInputs.senderDomain)),
                invalidCommand.publicInputs.pubkeyHash
            ),
            abi.encode(false)
        );

        // Should revert due to invalid DKIM key
        vm.expectRevert();
        _registrar.claimAndWithdraw(abi.encode(invalidCommand));
    }

    function test_SupportsMultipleHandles() public {
        // Claim first handle
        address account1 = _registrar.claimAndWithdraw(_validEncodedCommand);

        // Create second command for different handle
        ClaimXHandleCommand memory command2 = _validCommand;
        command2.publicInputs.xHandle = "differenthandle";
        command2.publicInputs.emailNullifier = keccak256("nullifier2");

        bytes32 ensNode2 = keccak256(bytes(command2.publicInputs.xHandle));
        address predictedAddr2 = _registrar.predictAddress(ensNode2);

        // Pre-fund second address
        vm.deal(predictedAddr2, 0.5 ether);

        // Mock verifier for second command
        vm.mockCall(address(_verifier), abi.encodeWithSelector(IVerifier.verify.selector), abi.encode(true));

        // Claim second handle
        address account2 = _registrar.claimAndWithdraw(abi.encode(command2));

        // Verify both accounts exist and are different
        assertTrue(account1 != account2, "Different handles should have different accounts");
        assertEq(_registrar.getAccount(_ensNode), account1, "First account should be stored");
        assertEq(_registrar.getAccount(ensNode2), account2, "Second account should be stored");
    }
}

