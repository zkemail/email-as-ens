// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { MinimalAccount } from "../accounts/MinimalAccount.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { ClaimHandleCommand } from "../verifiers/ClaimHandleCommandVerifier.sol";
import { IVerifier } from "../interfaces/IVerifier.sol";
import { IEntryPoint } from "../interfaces/IEntryPoint.sol";

contract HandleRegistrar is IEntryPoint {
    address public immutable implementation;
    address public immutable verifier;
    bytes32 public immutable rootNode; // e.g., namehash("x.zkemail.eth")

    mapping(bytes32 ensNode => address account) public accounts;
    mapping(bytes32 nullifier => bool used) internal _isUsed;

    event AccountClaimed(
        bytes32 indexed ensNode, address indexed account, address indexed target, uint256 withdrawnAmount
    );

    error InvalidProof();
    error NullifierUsed();

    constructor(address _verifier, bytes32 _rootNode) {
        implementation = address(new MinimalAccount());
        verifier = _verifier;
        rootNode = _rootNode;
    }

    /**
     * @inheritdoc IEntryPoint
     * @dev Entry point for the relayer to claim an account and withdraw ETH
     */
    function entrypoint(bytes memory data) external {
        ClaimHandleCommand memory command = abi.decode(data, (ClaimHandleCommand));

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

        // Get the ENS node from the handle in the proof
        // Convert handle to ENS node: handle.x.zkemail.eth
        bytes32 ensNode = _getEnsNode(command.publicInputs.handle);
        address account = predictAddress(ensNode);

        // Deploy the account if it doesn't exist
        if (accounts[ensNode] == address(0)) {
            account = Clones.cloneDeterministic(implementation, ensNode);
            accounts[ensNode] = account;
            MinimalAccount(payable(account)).initialize(address(this), ensNode);
            MinimalAccount(payable(account)).setOperator(address(this));
        }

        // Withdraw all ETH from the account to the target address
        uint256 balance = account.balance;
        if (balance > 0) {
            MinimalAccount(payable(account)).execute(command.target, balance, new bytes(0));
        }

        emit AccountClaimed(ensNode, account, command.target, balance);
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
     * @notice Predicts the address of a MinimalAccount for a given ENS node
     * @param ensNode The ENS node (namehash) to predict the address for
     * @return The predicted address of the account
     */
    function predictAddress(bytes32 ensNode) public view returns (address) {
        return Clones.predictDeterministicAddress(implementation, ensNode, address(this));
    }

    /**
     * @notice Converts an handle to an ENS node
     * @param handle The handle (e.g., "thezdev1" or "TheZDev1")
     * @return The ENS node (namehash of lowercase handle)
     */
    function _getEnsNode(string memory handle) internal view returns (bytes32) {
        // Normalize to lowercase first (ENS names are case-insensitive)
        string memory lowercaseHandle = _toLowercase(handle);
        // Create the label hash for the handle
        bytes32 labelHash = keccak256(bytes(lowercaseHandle));
        // Compute namehash: keccak256(rootNode, labelHash)
        return keccak256(abi.encodePacked(rootNode, labelHash));
    }

    /**
     * @notice Converts a string to lowercase
     * @param str The input string
     * @return The lowercase version of the string
     */
    function _toLowercase(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint256 i = 0; i < bStr.length; i++) {
            // If uppercase letter (A-Z is 65-90 in ASCII)
            if (bStr[i] >= 0x41 && bStr[i] <= 0x5A) {
                // Convert to lowercase by adding 32
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }

        return string(bLower);
    }
}
