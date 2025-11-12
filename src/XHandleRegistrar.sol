// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { MinimalAccount } from "./accounts/MinimalAccount.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ClaimXHandleCommand } from "./verifiers/ClaimXHandleCommandVerifier.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { IEntryPoint } from "./interfaces/IEntryPoint.sol";

contract XHandleRegistrar is IEntryPoint {
    address public immutable implementation;
    address public immutable verifier;

    mapping(bytes32 ensNode => address account) public accounts;
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event AccountClaimed(
        bytes32 indexed ensNode, address indexed account, address indexed target, uint256 withdrawnAmount
    );

    error InvalidProof();
    error NullifierUsed();

    constructor(address _verifier) {
        implementation = address(new MinimalAccount());
        verifier = _verifier;
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Entry point for the relayer to call claimAndWithdraw
     */
    function entrypoint(bytes memory data) external {
        claimAndWithdraw(data);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Delegates encoding to the configured verifier contract
     */
    function encode(bytes calldata proof, bytes32[] calldata publicInputs) external view returns (bytes memory) {
        return IVerifier(verifier).encode(proof, publicInputs);
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Returns the address of the DKIM registry from the verifier
     */
    function dkimRegistryAddress() external view returns (address) {
        return IVerifier(verifier).dkimRegistryAddress();
    }

    /**
     * @notice Gets the account address for a given ENS node
     * @param ensNode The ENS node to query
     * @return The account address, or address(0) if not created
     */
    function getAccount(bytes32 ensNode) external view returns (address) {
        return accounts[ensNode];
    }

    /**
     * @notice Checks if a nullifier has been used
     * @param nullifier The nullifier to check
     * @return True if the nullifier has been used, false otherwise
     */
    function isNullifierUsed(bytes32 nullifier) external view returns (bool) {
        return _isUsed[nullifier];
    }

    /**
     * @notice Claims an account for the given ENS node and withdraws all ETH to the target address
     * @dev Verifies the proof using ClaimXHandleCommandVerifier, deploys account if not exists, and withdraws ETH
     * @param data Encoded ClaimXHandleCommand containing proof, public inputs, and target address
     * @return account The address of the claimed account
     */
    function claimAndWithdraw(bytes memory data) public returns (address account) {
        ClaimXHandleCommand memory command = abi.decode(data, (ClaimXHandleCommand));

        // Check nullifier hasn't been used
        bytes32 emailNullifier = command.publicInputs.emailNullifier;
        if (_isUsed[emailNullifier]) {
            revert NullifierUsed();
        }
        _isUsed[emailNullifier] = true;

        // Verify the proof
        if (!IVerifier(verifier).verify(data)) {
            revert InvalidProof();
        }

        // Get the ENS node from the x handle in the proof
        bytes32 ensNode = keccak256(bytes(command.publicInputs.xHandle));
        account = predictAddress(ensNode);

        // Deploy the account if it doesn't exist
        if (accounts[ensNode] == address(0)) {
            account = Clones.cloneDeterministic(implementation, ensNode);
            MinimalAccount(payable(account)).initialize(address(this), ensNode);
            MinimalAccount(payable(account)).setOperator(address(this));
            accounts[ensNode] = account;
        }

        // Withdraw all ETH from the account to the target address
        uint256 balance = account.balance;
        if (balance > 0) {
            MinimalAccount(payable(account)).execute(command.target, balance, new bytes(0));
        }

        emit AccountClaimed(ensNode, account, command.target, balance);
    }

    /**
     * @notice Predicts the address of a MinimalAccount for a given ENS node
     * @param ensNode The ENS node (namehash) to predict the address for
     * @return The predicted address of the account
     */
    function predictAddress(bytes32 ensNode) public view returns (address) {
        return Clones.predictDeterministicAddress(implementation, ensNode, address(this));
    }
}
