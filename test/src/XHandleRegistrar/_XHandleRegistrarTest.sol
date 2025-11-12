// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { XHandleRegistrarHelper } from "./_XHandleRegistrarHelper.sol";
import { HandleCommandTestFixture } from "../../fixtures/handleCommand/HandleCommandTestFixture.sol";
import { HonkVerifier } from "../../fixtures/handleCommand/HonkVerifier.sol";
import {
    ClaimXHandleCommand,
    ClaimXHandleCommandVerifier
} from "../../../src/verifiers/ClaimXHandleCommandVerifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { EnsUtils } from "../../../src/utils/EnsUtils.sol";

abstract contract XHandleRegistrarTest is Test {
    using EnsUtils for bytes;

    XHandleRegistrarHelper internal _registrar;
    ClaimXHandleCommandVerifier internal _verifier;
    address internal _dkimRegistry;
    bytes32 internal _rootNode;

    ClaimXHandleCommand internal _validCommand;
    bytes internal _validEncodedCommand;
    bytes32 internal _ensNode;

    function setUp() public virtual {
        // Get the valid command from fixture
        (_validCommand,) = HandleCommandTestFixture.getClaimXFixture();

        // Setup DKIM registry mock
        _dkimRegistry = makeAddr("dkimRegistry");
        vm.mockCall(
            _dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(_validCommand.publicInputs.senderDomain)),
                _validCommand.publicInputs.pubkeyHash
            ),
            abi.encode(true)
        );

        // Calculate root node: namehash("x.zkemail.eth")
        _rootNode = bytes("x.zkemail.eth").namehash();

        // Deploy verifier and registrar
        _verifier = new ClaimXHandleCommandVerifier(address(new HonkVerifier()), _dkimRegistry);
        _registrar = new XHandleRegistrarHelper(address(_verifier), _rootNode);

        // Calculate ENS node from x handle: namehash("xhandle.x.zkemail.eth")
        bytes32 labelHash = keccak256(bytes(_validCommand.publicInputs.xHandle));
        _ensNode = keccak256(abi.encodePacked(_rootNode, labelHash));
        _validEncodedCommand = abi.encode(_validCommand);
    }
}

