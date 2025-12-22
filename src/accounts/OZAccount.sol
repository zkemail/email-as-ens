// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Account } from "@openzeppelin/contracts/account/Account.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SignerECDSA } from "@openzeppelin/contracts/utils/cryptography/signers/SignerECDSA.sol";

contract OZAccount is Account, SignerECDSA, Ownable {
    constructor(address owner) Ownable(owner) SignerECDSA(address(0)) { }

    function setECDSASigner(address signer) external onlyOwner {
        _setSigner(signer);
    }
}
