// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { IExtendedResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IExtendedResolver.sol";
import { NameCoder } from "@ensdomains/ens-contracts/contracts/utils/NameCoder.sol";
import { ITextResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol";
import { IAddrResolver } from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract XHandleResolver is IExtendedResolver, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    // https://docs.ens.domains/ensip/23
    error UnsupportedResolverProfile(bytes4 selector);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    function initialize() external initializer {
        __Ownable_init(msg.sender);
    }

    /// @notice Resolves a name, as specified by ENSIP 10.
    /// @param name The DNS-encoded name to resolve.
    /// @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32),
    /// text(bytes32,string), etc). @return The return data, ABI encoded identically to the underlying function.
    function resolve(bytes calldata name, bytes calldata data) external view override returns (bytes memory) {
        string memory decodedName = NameCoder.decode(name); // This will be "x.platform.zkemail.eth"
        bytes4 selector = bytes4(data);

        if (selector == ITextResolver.text.selector) {
            (, string memory key) = abi.decode(data[4:], (bytes32, string));
            bytes32 hashedKey = keccak256(bytes(key));

            if (hashedKey == keccak256(bytes("description"))) {
                return abi.encode("Claim your tips from the zkEmail dashboard");
            }

            if (hashedKey == keccak256(bytes("url"))) {
                return abi.encode(string(abi.encodePacked("https://zk.email/", decodedName)));
            }

            return abi.encode("");
        }

        // addr(node)
        if (selector == IAddrResolver.addr.selector) {
            return abi.encode(address(uint160(uint256(keccak256(abi.encode(decodedName))))));
        }

        revert UnsupportedResolverProfile(selector);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IExtendedResolver).interfaceId;
    }

    /// @notice Authorizes an upgrade to a new implementation
    /// @dev Only the owner can authorize upgrades
    function _authorizeUpgrade(address) internal override onlyOwner { }
}
