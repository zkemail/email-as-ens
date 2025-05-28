// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { TestFixtures } from "./fixtures/TestFixtures.sol";
import { ProveAndClaimCommand, ProveAndClaimCommandVerifier } from "../src/utils/Verifier.sol";
import { Groth16Verifier } from "./fixtures/Groth16Verifier.sol";

contract VerifierTest is ProveAndClaimCommandVerifier {
    constructor() ProveAndClaimCommandVerifier(address(0)) { }

    function buildPubSignals(ProveAndClaimCommand memory command) public pure returns (uint256[60] memory) {
        return _buildPubSignals(command);
    }
}

contract FixturesTest is Test {
    ProveAndClaimCommandVerifier _verifier;

    function setUp() public {
        _verifier = new ProveAndClaimCommandVerifier(address(new Groth16Verifier()));
    }

    function test_buildPublicSignlas_correctlyBuildsSignalsFromCommand() public {
        ProveAndClaimCommand memory command = TestFixtures.claimEnsCommand();

        // Field elements below represent ASCII text (reversed) and represented as bn128 filed elements.
        // ASCII text is encoded as big-endian integers and then reversed.
        //
        // To verify ASCII conversion in Python:
        // def field_to_ascii(field_value):
        //     hex_str = hex(field_value)[2:]
        //     if len(hex_str) % 2:
        //         hex_str = '0' + hex_str
        //     bytes_data = bytes.fromhex(hex_str)
        //     return bytes_data.decode('ascii').rstrip('\x00')[::-1]  # reverse
        //
        // Example: field_to_ascii(2_018_721_414_038_404_820_327) returns "gmail.com"
        uint256[60] memory expectedPubSignals = [
            // "gmail.com" - email domain (9 parts)
            2_018_721_414_038_404_820_327,
            0, // part 2
            0, // part 3
            0, // part 4
            0, // part 5
            0, // part 6
            0, // part 7
            0, // part 8
            0, // part 9
            // dkim signer Poseidon hash
            6_632_353_713_085_157_925_504_008_443_078_919_716_322_386_156_160_602_218_536_961_028_046_468_237_192,
            // nullifier
            4_554_837_866_351_681_469_140_157_310_807_394_956_517_436_905_901_938_745_944_947_421_127_000_894_884,
            // timestamp - not enabled in circuits
            0,
            // "Claim ENS name for address 0xafBD210c60dD651892a61804A989eEF7bD63CBA0" - command text (20 parts)
            180_891_110_264_973_503_160_226_225_538_030_206_223_858_091_522_603_795_023_666_265_748_100_181_059,
            173_532_502_901_810_909_445_165_194_544_006_900_992_761_359_126_983_071_590_425_318_149_531_518_018,
            13_582_551_733_188_164, // part 3
            0, // part 4
            0, // part 5
            0, // part 6
            0, // part 7
            0, // part 8
            0, // part 9
            0, // part 10
            0, // part 11
            0, // part 12
            0, // part 13
            0, // part 14
            0, // part 15
            0, // part 16
            0, // part 17
            0, // part 18
            0, // part 19
            0, // part 20
            // account salt. Poseidon(email, accountCode a.k.a the private salt).
            // not enforced in ENS context as email is public.
            6_462_823_065_239_948_963_336_625_999_299_932_081_772_838_850_050_016_167_388_148_022_706_945_490_790,
            // Boolean, 0 or 1.
            // 1: private account code has been included in the sender email
            // 0: it provided by the relayer
            0,
            // RSA public key modulus
            2_107_195_391_459_410_975_264_579_855_291_297_887, // part 1
            2_562_632_063_603_354_817_278_035_230_349_645_235, // part 2
            1_868_388_447_387_859_563_289_339_873_373_526_818, // part 3
            2_159_353_473_203_648_408_714_805_618_210_333_973, // part 4
            351_789_365_378_952_303_483_249_084_740_952_389, // part 5
            659_717_315_519_250_910_761_248_850_885_776_286, // part 6
            1_321_773_785_542_335_225_811_636_767_147_612_036, // part 7
            258_646_249_156_909_342_262_859_240_016_844_424, // part 8
            644_872_192_691_135_519_287_736_182_201_377_504, // part 9
            174_898_460_680_981_733_302_111_356_557_122_107, // part 10
            1_068_744_134_187_917_319_695_255_728_151_595_132, // part 11
            1_870_792_114_609_696_396_265_442_109_963_534_232, // part 12
            8_288_818_605_536_063_568_933_922_407_756_344, // part 13
            1_446_710_439_657_393_605_686_016_190_803_199_177, // part 14
            2_256_068_140_678_002_554_491_951_090_436_701_670, // part 15
            518_946_826_903_468_667_178_458_656_376_730_744, // part 16
            3_222_036_726_675_473_160_989_497_427_257_757, // part 17
            // "thezdev3@gmail.com" - sender email address (9 parts)
            9_533_142_343_906_178_599_764_761_233_821_773_221_685_364,
            0, // part 2
            0, // part 3
            0, // part 4
            0, // part 5
            0, // part 6
            0, // part 7
            0, // part 8
            0 // part 9
        ];

        VerifierTest verifier = new VerifierTest();
        uint256[60] memory publicSignals = verifier.buildPubSignals(command);

        for (uint8 i = 0; i < 60; i++) {
            assertEq(publicSignals[i], expectedPubSignals[i]);
        }
    }
}
