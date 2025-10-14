// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";

/**
 * @title TestUtils
 * @notice Provides utility functions for testing
 */
contract TestUtils is Test {
    /**
     * @notice Mocks a function call and expects it to be called
     * @dev This function is used to mock a function call and expect it to be called
     * @param _target The address of the target contract
     * @param _call The call data
     * @param _ret The return data
     */
    function _mockAndExpect(address _target, bytes memory _call, bytes memory _ret) internal {
        vm.mockCall(_target, _call, _ret);
        vm.expectCall(_target, _call);
    }

    /**
     * @notice Mocks DKIM registry to return valid for a specific domain and key hash
     * @param dkimRegistry The address of the DKIM registry
     * @param domainName The domain name to mock
     * @param publicKeyHash The public key hash to mock
     * @param isValid Whether the key hash should be valid
     */
    function _mockDkimRegistryValidity(
        address dkimRegistry,
        string memory domainName,
        bytes32 publicKeyHash,
        bool isValid
    )
        internal
    {
        vm.mockCall(
            dkimRegistry,
            abi.encodeWithSelector(IDKIMRegistry.isKeyHashValid.selector, keccak256(bytes(domainName)), publicKeyHash),
            abi.encode(isValid)
        );
    }

    /**
     * @notice Creates a mock DKIM registry address and mocks it to return valid for a domain and key
     * @param domainName The domain name to mock as valid
     * @param publicKeyHash The public key hash to mock as valid
     * @return dkimRegistry The mocked DKIM registry address
     */
    function _createMockDkimRegistry(
        string memory domainName,
        bytes32 publicKeyHash
    )
        internal
        returns (address dkimRegistry)
    {
        dkimRegistry = makeAddr("dkimRegistry");
        _mockDkimRegistryValidity(dkimRegistry, domainName, publicKeyHash, true);
    }
}
