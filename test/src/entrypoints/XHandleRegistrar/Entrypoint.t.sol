// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { XHandleRegistrarTest } from "./_XHandleRegistrarTest.sol";
import { XHandleRegistrar } from "../../../../src/entrypoints/XHandleRegistrar.sol";
import { ClaimXHandleCommand } from "../../../../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { IVerifier } from "../../../../src/interfaces/IVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

contract EntrypointTest is XHandleRegistrarTest {
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

        // Claim and withdraw via entrypoint
        _registrar.entrypoint(_validEncodedCommand);

        // Get deployed account from mapping
        address deployedAccount = _registrar.getAccount(_ensNode);

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

        // Claim and withdraw via entrypoint
        _registrar.entrypoint(_validEncodedCommand);

        // Get deployed account from mapping
        address deployedAccount = _registrar.getAccount(_ensNode);

        // Verify account was deployed
        assertEq(deployedAccount, predictedAddr, "Account should be deployed at predicted address");

        // Verify no ETH was transferred
        assertEq(_validCommand.target.balance, targetInitialBalance, "Target balance should not change");
    }

    function test_SecondClaimWithDifferentNullifierWorks() public {
        // First claim deploys the account
        _registrar.entrypoint(_validEncodedCommand);

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
        _registrar.entrypoint(abi.encode(secondCommand));

        // Verify withdrawal happened
        assertEq(_validCommand.target.balance, targetBalance + secondFundAmount, "Second withdrawal should succeed");
    }

    function test_RevertsWhen_NullifierReused() public {
        // First successful claim
        _registrar.entrypoint(_validEncodedCommand);

        // Verify nullifier is marked as used
        bool isUsed = _registrar.isNullifierUsed(_validCommand.publicInputs.emailNullifier);
        assertTrue(isUsed, "Nullifier should be marked as used after first claim");

        // Try to claim again with same nullifier
        vm.expectRevert(XHandleRegistrar.NullifierUsed.selector);
        _registrar.entrypoint(_validEncodedCommand);
    }

    function test_RevertsWhen_InvalidProof() public {
        // Corrupt the proof
        ClaimXHandleCommand memory invalidCommand = _validCommand;
        bytes memory corruptedProof = new bytes(invalidCommand.proof.length);
        corruptedProof[0] = invalidCommand.proof[0] ^ bytes1(uint8(1));
        invalidCommand.proof = corruptedProof;

        // Should revert due to invalid proof
        vm.expectRevert();
        _registrar.entrypoint(abi.encode(invalidCommand));
    }

    function test_RevertsWhen_VerifierReturnsFalse() public {
        // Create a command with a fresh nullifier
        ClaimXHandleCommand memory command = _validCommand;
        command.publicInputs.emailNullifier = keccak256("fresh_nullifier");

        // Mock the verifier to return false (instead of reverting)
        vm.mockCall(address(_verifier), abi.encodeWithSelector(IVerifier.verify.selector), abi.encode(false));

        // Should revert with InvalidProof error
        vm.expectRevert(XHandleRegistrar.InvalidProof.selector);
        _registrar.entrypoint(abi.encode(command));
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
        _registrar.entrypoint(abi.encode(invalidCommand));
    }

    function test_SupportsMultipleHandles() public {
        // Claim first handle
        _registrar.entrypoint(_validEncodedCommand);
        address account1 = _registrar.getAccount(_ensNode);

        // Create second command for different handle
        ClaimXHandleCommand memory command2 = _validCommand;
        command2.publicInputs.xHandle = "differenthandle";
        command2.publicInputs.emailNullifier = keccak256("nullifier2");

        // Calculate ENS node with lowercase (same as registrar does)
        string memory lowercaseHandle = _toLowercase(command2.publicInputs.xHandle);
        bytes32 labelHash2 = keccak256(bytes(lowercaseHandle));
        bytes32 ensNode2 = keccak256(abi.encodePacked(_rootNode, labelHash2));
        address predictedAddr2 = _registrar.predictAddress(ensNode2);

        // Pre-fund second address
        vm.deal(predictedAddr2, 0.5 ether);

        // Mock verifier for second command
        vm.mockCall(address(_verifier), abi.encodeWithSelector(IVerifier.verify.selector), abi.encode(true));

        // Claim second handle
        _registrar.entrypoint(abi.encode(command2));
        address account2 = _registrar.getAccount(ensNode2);

        // Verify both accounts exist and are different
        assertTrue(account1 != account2, "Different handles should have different accounts");
        assertEq(_registrar.getAccount(_ensNode), account1, "First account should be stored");
        assertEq(_registrar.getAccount(ensNode2), account2, "Second account should be stored");
    }

    function test_NormalizesUppercaseHandleToLowercase() public {
        // Create command with uppercase handle
        ClaimXHandleCommand memory command = _validCommand;
        command.publicInputs.xHandle = "TheZDev1"; // Mixed case
        command.publicInputs.emailNullifier = keccak256("uppercase_nullifier");

        // Calculate expected ENS node using lowercase version
        bytes32 labelHash = keccak256(bytes("thezdev1")); // lowercase
        bytes32 expectedEnsNode = keccak256(abi.encodePacked(_rootNode, labelHash));
        address predictedAddr = _registrar.predictAddress(expectedEnsNode);

        // Pre-fund the predicted address
        vm.deal(predictedAddr, 1 ether);

        // Mock verifier to accept this command
        vm.mockCall(address(_verifier), abi.encodeWithSelector(IVerifier.verify.selector), abi.encode(true));

        // Claim with uppercase handle via entrypoint
        _registrar.entrypoint(abi.encode(command));

        // Get deployed account from mapping
        address deployedAccount = _registrar.getAccount(expectedEnsNode);

        // Verify account was deployed at predicted address (using lowercase ENS node)
        assertEq(deployedAccount, predictedAddr, "Account should be at lowercase ENS node address");
        assertEq(
            _registrar.getAccount(expectedEnsNode), deployedAccount, "Account should be stored under lowercase node"
        );
    }
}

