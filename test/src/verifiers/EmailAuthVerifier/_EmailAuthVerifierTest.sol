// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { PublicInputs } from "../../../../src/verifiers/EmailAuthVerifier.sol";

abstract contract _EmailAuthVerifierTest is Test {
    function _assertPublicInputsEq(PublicInputs memory decoded, PublicInputs memory expected) internal pure {
        assertEq(decoded.domainName, expected.domainName, "domainName mismatch");
        assertEq(decoded.emailAddress, expected.emailAddress, "emailAddress mismatch");
        assertEq(decoded.publicKeyHash, expected.publicKeyHash, "publicKeyHash mismatch");
        assertEq(decoded.emailNullifier, expected.emailNullifier, "emailNullifier mismatch");
        assertEq(decoded.timestamp, expected.timestamp, "timestamp mismatch");
        assertEq(decoded.accountSalt, expected.accountSalt, "accountSalt mismatch");
        assertEq(decoded.isCodeExist, expected.isCodeExist, "isCodeExist mismatch");
    }
}
