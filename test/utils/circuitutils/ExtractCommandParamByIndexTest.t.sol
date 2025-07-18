// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { Test } from "forge-std/Test.sol";
import { CircuitUtils } from "../../../src/utils/CircuitUtils.sol";
import { CommandUtils } from "@zk-email/email-tx-builder/src/libraries/CommandUtils.sol";

contract ExtractCommandParamByIndexTest is Test {
    function test_simpleStringParameter() public pure {
        string[] memory template = new string[](2);
        template[0] = "String:";
        template[1] = CommandUtils.STRING_MATCHER;

        string memory command = "String: username";
        string memory result = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        assertEq(result, "username");
    }

    function test_ethAddressParameter() public pure {
        string[] memory template = new string[](4);
        template[0] = "Address:";
        template[1] = CommandUtils.ETH_ADDR_MATCHER;

        string memory command = "Address: 0xafBD210c60dD651892a61804A989eEF7bD63CBA0";
        string memory result = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        assertEq(result, "0xafBD210c60dD651892a61804A989eEF7bD63CBA0");
    }

    function test_multipleParameters() public pure {
        string[] memory template = new string[](4);
        template[0] = "Address1:";
        template[1] = CommandUtils.ETH_ADDR_MATCHER;
        template[2] = "Address2:";
        template[3] = CommandUtils.ETH_ADDR_MATCHER;

        string memory command =
            "Address1: 0x0000000000000000000000000000000000000000 Address2: 0x1111111111111111111111111111111111111111";
        string memory result1 = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        string memory result2 = CircuitUtils.extractCommandParamByIndex(template, command, 1);
        assertEq(result1, "0x0000000000000000000000000000000000000000");
        assertEq(result2, "0x1111111111111111111111111111111111111111");
    }

    function test_parameterIndexOutOfBounds() public pure {
        string[] memory template = new string[](2);
        template[0] = "Address:";
        template[1] = CommandUtils.ETH_ADDR_MATCHER;

        string memory command = "Address: 0xafBD210c60dD651892a61804A989eEF7bD63CBA0";
        string memory result = CircuitUtils.extractCommandParamByIndex(template, command, 2);
        assertEq(result, "");
    }

    function test_noParameters() public pure {
        string[] memory template = new string[](2);
        template[0] = "PING";
        template[1] = "PONG";

        string memory command = "PING PONG";
        string memory result = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        assertEq(result, "");
    }

    function test_parameterAtStart() public pure {
        string[] memory template = new string[](2);
        template[0] = CommandUtils.STRING_MATCHER;
        template[1] = "!";

        string memory command = "username !";
        string memory result = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        assertEq(result, "username");
    }

    function test_consecutiveParameters() public pure {
        string[] memory template = new string[](4);
        template[0] = CommandUtils.STRING_MATCHER;
        template[1] = CommandUtils.UINT_MATCHER;
        template[2] = CommandUtils.STRING_MATCHER;
        template[3] = "!";

        string memory command = "user 123 token !";
        string memory result1 = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        string memory result2 = CircuitUtils.extractCommandParamByIndex(template, command, 1);
        string memory result3 = CircuitUtils.extractCommandParamByIndex(template, command, 2);

        assertEq(result1, "user");
        assertEq(result2, "123");
        assertEq(result3, "token");
    }

    function test_realEnsClaimCommand() public pure {
        string[] memory template = new string[](9);
        template[0] = "Claim";
        template[1] = "ENS";
        template[2] = "name";
        template[3] = "for";
        template[4] = "address";
        template[5] = CommandUtils.ETH_ADDR_MATCHER;
        template[6] = "with";
        template[7] = "resolver";
        template[8] = CommandUtils.STRING_MATCHER;

        string memory command =
            "Claim ENS name for address 0xafBD210c60dD651892a61804A989eEF7bD63CBA0 with resolver resolver.eth";
        string memory result1 = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        string memory result2 = CircuitUtils.extractCommandParamByIndex(template, command, 1);

        assertEq(result1, "0xafBD210c60dD651892a61804A989eEF7bD63CBA0");
        assertEq(result2, "resolver.eth");
    }

    function test_simpleEnsClaimCommand() public pure {
        string[] memory template = new string[](6);
        template[0] = "Claim";
        template[1] = "ENS";
        template[2] = "name";
        template[3] = "for";
        template[4] = "address";
        template[5] = CommandUtils.ETH_ADDR_MATCHER;

        string memory command = "Claim ENS name for address 0xafBD210c60dD651892a61804A989eEF7bD63CBA0";
        string memory result = CircuitUtils.extractCommandParamByIndex(template, command, 0);
        assertEq(result, "0xafBD210c60dD651892a61804A989eEF7bD63CBA0");
    }
}
