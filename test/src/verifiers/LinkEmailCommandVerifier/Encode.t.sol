// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { TestFixtures } from "../../../fixtures/TestFixtures.sol";
import { Groth16Verifier } from "../../../fixtures/Groth16Verifier.sol";
import { IDKIMRegistry } from "@zk-email/contracts/interfaces/IERC7969.sol";
import { TestUtils } from "../../../TestUtils.sol";
import { LinkEmailCommand, LinkEmailCommandVerifier } from "../../../../src/verifiers/LinkEmailCommandVerifier.sol";
import { _EmailAuthVerifierTest } from "../EmailAuthVerifier/_EmailAuthVerifierTest.sol";

contract EncodeTest is _EmailAuthVerifierTest {
    LinkEmailCommandVerifier internal _verifier;

    function setUp() public {
        address dkimRegistry = makeAddr("dkimRegistry");
        _verifier = new LinkEmailCommandVerifier(address(new Groth16Verifier()), dkimRegistry);
        // configure DKIM mock with valid domain+key
        (LinkEmailCommand memory command,) = TestFixtures.linkEmailCommand();
        vm.mockCall(
            dkimRegistry,
            abi.encodeWithSelector(
                IDKIMRegistry.isKeyHashValid.selector,
                keccak256(bytes(command.emailAuthProof.publicInputs.domainName)),
                command.emailAuthProof.publicInputs.publicKeyHash
            ),
            abi.encode(true)
        );
    }

    function test_correctlyEncodesAndDecodesCommand() public view {
        (LinkEmailCommand memory command, bytes32[] memory expectedPublicInputs) = TestFixtures.linkEmailCommand();

        bytes memory encodedData = _verifier.encode(command.emailAuthProof.proof, expectedPublicInputs);
        LinkEmailCommand memory decodedCommand = abi.decode(encodedData, (LinkEmailCommand));

        assertEq(decodedCommand.textRecord.ensName, command.textRecord.ensName);
        assertEq(decodedCommand.textRecord.value, command.textRecord.value);
        _assertPublicInputsEq(decodedCommand.emailAuthProof.publicInputs, command.emailAuthProof.publicInputs);
    }
}
