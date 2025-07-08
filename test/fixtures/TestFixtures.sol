// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { ProveAndClaimCommand } from "../../src/utils/Verifier.sol";

/**
 * @title TestFixtures
 * @notice Provides test data and fixtures for ZK Email ENS registrar testing
 * @dev This library contains pre-computed test data including valid ProveAndClaimCommand structs
 *      and their corresponding expected public signals for verification testing.
 *
 *      The test data includes:
 *      - A complete ProveAndClaimCommand with real cryptographic proof components
 *      - The expected 60-element public signals array for proof verification
 *      - ASCII text representations encoded as BN128 field elements
 *      - Valid RSA public key components for DKIM verification
 *
 *      This data is used to test the verifier's ability to correctly process and verify
 *      email-based ENS claims without requiring live email generation during testing.
 */
library TestFixtures {
    /**
     * @notice Provides a complete test case for ENS claim verification
     * @return command A fully populated ProveAndClaimCommand struct with test data
     * @return expectedPubSignals The expected 60-element public signals array for verification
     * @dev This function returns test data representing a claim for "thezdev3[at]gmail.com" to be
     *      mapped to ENS name ownership by address 0xafBD210c60dD651892a61804A989eEF7bD63CBA0.
     *
     *      The returned data includes:
     *      - Domain: "gmail.com"
     *      - Email: "thezdev3[at]gmail.com"
     *      - Owner: 0xafBD210c60dD651892a61804A989eEF7bD63CBA0
     *      - Valid ZK proof components (pA, pB, pC) for Groth16 verification
     *      - DKIM signer hash for Gmail's public key
     *      - Nullifier to prevent replay attacks
     *      - RSA public key components encoded in miscellaneousData
     *
     *      The expectedPubSignals array contains field elements representing:
     *      1. Domain name "gmail.com" (packed into 9 fields)
     *      2. DKIM signer hash (1 field)
     *      3. Email nullifier (1 field)
     *      4. Timestamp (1 field, set to 0)
     *      5. Command text "Claim ENS name for address 0x..." (packed into 20 fields)
     *      6. Account salt (1 field)
     *      7. Code embedded flag (1 field, set to 0)
     *      8. RSA public key modulus (17 fields)
     *      9. Email address "thezdev3[at]gmail.com" (packed into 9 fields)
     *
     *      ASCII text conversion note:
     *      Field elements represent ASCII text in reversed byte order. To verify conversion:
     *      ```python
     *      def field_to_ascii(field_value):
     *          hex_str = hex(field_value)[2:]
     *          if len(hex_str) % 2:
     *              hex_str = '0' + hex_str
     *          bytes_data = bytes.fromhex(hex_str)
     *          return bytes_data.decode('ascii').rstrip('\x00')[::-1]  # reverse
     *      ```
     *
     *      Example: field_to_ascii(2_018_721_414_038_404_820_327) returns "gmail.com"
     */
    function claimEnsCommand()
        internal
        pure
        returns (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals)
    {
        // RSA public key modulus decomposed into 17 field elements for ZK circuit compatibility
        // This represents Gmail's DKIM public key used for signature verification
        uint256[17] memory pubkey = [
            uint256(2_107_195_391_459_410_975_264_579_855_291_297_887),
            uint256(2_562_632_063_603_354_817_278_035_230_349_645_235),
            uint256(1_868_388_447_387_859_563_289_339_873_373_526_818),
            uint256(2_159_353_473_203_648_408_714_805_618_210_333_973),
            uint256(351_789_365_378_952_303_483_249_084_740_952_389),
            uint256(659_717_315_519_250_910_761_248_850_885_776_286),
            uint256(1_321_773_785_542_335_225_811_636_767_147_612_036),
            uint256(258_646_249_156_909_342_262_859_240_016_844_424),
            uint256(644_872_192_691_135_519_287_736_182_201_377_504),
            uint256(174_898_460_680_981_733_302_111_356_557_122_107),
            uint256(1_068_744_134_187_917_319_695_255_728_151_595_132),
            uint256(1_870_792_114_609_696_396_265_442_109_963_534_232),
            uint256(8_288_818_605_536_063_568_933_922_407_756_344),
            uint256(1_446_710_439_657_393_605_686_016_190_803_199_177),
            uint256(2_256_068_140_678_002_554_491_951_090_436_701_670),
            uint256(518_946_826_903_468_667_178_458_656_376_730_744),
            uint256(3_222_036_726_675_473_160_989_497_427_257_757)
        ];

        // Groth16 proof component A (2 field elements)
        uint256[2] memory pA = [
            0x03e1490fc469798ca99a36702a322ccc8227cc3595058d0aac83aea22fbb2ccf,
            0x2551cd0add70fe3900b05e2dd03b7ba5102ddb63e1b4003ec839a537c6453cfc
        ];

        // Groth16 proof component B (2x2 field elements)
        uint256[2][2] memory pB = [
            [
                0x25c35e8d24d948a808a1ea128831cd54ce4a3532a40ab136dc81bbf0b2635c24,
                0x2e0054eaf867ca03c0f3668b7f17d3bf01b3d7f00bcadb774a74058f81273c97
            ],
            [
                0x144542d4082a8fadc1c55a24698522916f1717791bf1e1f115fb183c62a507da,
                0x2dc6e057e138dd1b7c10c1be1f99261b826cd4fcf081ae5a90885aab3358dca4
            ]
        ];

        // Groth16 proof component C (2 field elements)
        uint256[2] memory pC = [
            0x2ef0d8f5b88cdc952bcf26adeaa6a30176584496df21bd21fbc997432172c9e7,
            0x24b4201c52b7eec75377b727ac0fe51049d534bac7918175096596fa351862c1
        ];

        string[] memory emailParts = new string[](2);
        emailParts[0] = "thezdev3$gmail";
        emailParts[1] = "com";

        // Complete ProveAndClaimCommand struct with test data for "thezdev3@gmail.com"
        command = ProveAndClaimCommand({
            domain: "gmail.com",
            email: "thezdev3@gmail.com",
            emailParts: emailParts,
            owner: 0xafBD210c60dD651892a61804A989eEF7bD63CBA0,
            dkimSignerHash: hex"0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788",
            nullifier: hex"0A11F2664AE4F7E3A9C3BA43394B01347FD5B76FC0A7FDB09D91324DA1F6ADA4",
            timestamp: 0, // Gmail doesn't sign timestamps
            accountSalt: hex"0E49D406A4D84DA7DB65C161EB11D06E8C52F1C0EDD91BC557E4F23FF01D7F66",
            isCodeEmbedded: false, // Code provided by relayer, not embedded in email
            miscellaneousData: abi.encode(pubkey), // RSA public key components
            proof: abi.encode(pA, pB, pC) // Groth16 proof components
         });

        // Expected public signals array (60 elements) for proof verification
        // Field elements below represent ASCII text (reversed) encoded as BN128 field elements.
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
        expectedPubSignals = [
            // "gmail.com" - email domain (9 parts)
            2_018_721_414_038_404_820_327, // Contains "gmail.com"
            0, // part 2 (padding)
            0, // part 3 (padding)
            0, // part 4 (padding)
            0, // part 5 (padding)
            0, // part 6 (padding)
            0, // part 7 (padding)
            0, // part 8 (padding)
            0, // part 9 (padding)
            // dkim signer Poseidon hash
            6_632_353_713_085_157_925_504_008_443_078_919_716_322_386_156_160_602_218_536_961_028_046_468_237_192,
            // nullifier - prevents replay attacks
            4_554_837_866_351_681_469_140_157_310_807_394_956_517_436_905_901_938_745_944_947_421_127_000_894_884,
            // timestamp - not enabled in circuits for Gmail
            0,
            // "Claim ENS name for address 0xafBD210c60dD651892a61804A989eEF7bD63CBA0" - command text (20 parts)
            180_891_110_264_973_503_160_226_225_538_030_206_223_858_091_522_603_795_023_666_265_748_100_181_059, // part
                // 1
            173_532_502_901_810_909_445_165_194_544_006_900_992_761_359_126_983_071_590_425_318_149_531_518_018, // part
                // 2
            13_582_551_733_188_164, // part 3
            0, // part 4 (padding)
            0, // part 5 (padding)
            0, // part 6 (padding)
            0, // part 7 (padding)
            0, // part 8 (padding)
            0, // part 9 (padding)
            0, // part 10 (padding)
            0, // part 11 (padding)
            0, // part 12 (padding)
            0, // part 13 (padding)
            0, // part 14 (padding)
            0, // part 15 (padding)
            0, // part 16 (padding)
            0, // part 17 (padding)
            0, // part 18 (padding)
            0, // part 19 (padding)
            0, // part 20 (padding)
            // account salt. Poseidon(email, accountCode a.k.a the private salt).
            // not enforced in ENS context as email is public.
            6_462_823_065_239_948_963_336_625_999_299_932_081_772_838_850_050_016_167_388_148_022_706_945_490_790,
            // Boolean, 0 or 1.
            // 1: private account code has been included in the sender email
            // 0: it provided by the relayer
            0,
            // RSA public key modulus (17 parts)
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
            // Contains "thezdev3@gmail.com"
            9_533_142_343_906_178_599_764_761_233_821_773_221_685_364,
            0, // part 2 (padding)
            0, // part 3 (padding)
            0, // part 4 (padding)
            0, // part 5 (padding)
            0, // part 6 (padding)
            0, // part 7 (padding)
            0, // part 8 (padding)
            0 // part 9 (padding)
        ];

        return (command, expectedPubSignals);
    }

    function claimWithResolverCommand()
        internal
        pure
        returns (ProveAndClaimCommand memory command, uint256[60] memory expectedPubSignals)
    {
        // RSA public key modulus decomposed into 17 field elements for ZK circuit compatibility
        // This represents Gmail's DKIM public key used for signature verification
        uint256[17] memory pubkey = [
            uint256(2_107_195_391_459_410_975_264_579_855_291_297_887),
            uint256(2_562_632_063_603_354_817_278_035_230_349_645_235),
            uint256(1_868_388_447_387_859_563_289_339_873_373_526_818),
            uint256(2_159_353_473_203_648_408_714_805_618_210_333_973),
            uint256(351_789_365_378_952_303_483_249_084_740_952_389),
            uint256(659_717_315_519_250_910_761_248_850_885_776_286),
            uint256(1_321_773_785_542_335_225_811_636_767_147_612_036),
            uint256(258_646_249_156_909_342_262_859_240_016_844_424),
            uint256(644_872_192_691_135_519_287_736_182_201_377_504),
            uint256(174_898_460_680_981_733_302_111_356_557_122_107),
            uint256(1_068_744_134_187_917_319_695_255_728_151_595_132),
            uint256(1_870_792_114_609_696_396_265_442_109_963_534_232),
            uint256(8_288_818_605_536_063_568_933_922_407_756_344),
            uint256(1_446_710_439_657_393_605_686_016_190_803_199_177),
            uint256(2_256_068_140_678_002_554_491_951_090_436_701_670),
            uint256(518_946_826_903_468_667_178_458_656_376_730_744),
            uint256(3_222_036_726_675_473_160_989_497_427_257_757)
        ];

        // Groth16 proof component A (2 field elements)
        uint256[2] memory pA = [
            0x1f3b3846a2a0c441c2f5d75932e63571d4922659183422409f582d028e3535dc,
            0x05421c97e5102555776e9334c2642a8b965fce38634863a62883391d4e460451
        ];

        // Groth16 proof component B (2x2 field elements)
        uint256[2][2] memory pB = [
            [
                0x140344d5a71ac735233c1d482591605f4e1f7253573c71987585a024c0d16a53,
                0x2424b6113b2c21c76251b326d9620b1e19bf18146740645609462bf0c9e6c10b
            ],
            [
                0x1e809311ea3ad342898038676a6e719aaa9d6e469d74917578b871217e2f57d4,
                0x0874415858004128033282245552399521360052321528442301980334125804
            ]
        ];

        // Groth16 proof component C (2 field elements)
        uint256[2] memory pC = [
            0x192d19207e77e7486e9215011749652516483519545417861962383568969854,
            0x1131975b38270513636b13970b54359675276587396068224933943360214299
        ];

        string[] memory emailParts = new string[](2);
        emailParts[0] = "thezdev3$gmail";
        emailParts[1] = "com";

        // Complete ProveAndClaimCommand struct with test data for "thezdev3@gmail.com"
        command = ProveAndClaimCommand({
            domain: "gmail.com",
            email: "thezdev3@gmail.com",
            emailParts: emailParts,
            owner: 0xafBD210c60dD651892a61804A989eEF7bD63CBA0,
            dkimSignerHash: hex"0ea9c777dc7110e5a9e89b13f0cfc540e3845ba120b2b6dc24024d61488d4788",
            nullifier: hex"0C1324707AAD13359556F612269E9623D3F15A367B167195779D2D9A74E6F7F5",
            timestamp: 0, // Gmail doesn't sign timestamps
            accountSalt: hex"0AF3E4E80D263155F4D3C23B8B8A49D5276B8718E29ED4D8A41C90B598716552",
            isCodeEmbedded: false, // Code provided by relayer, not embedded in email
            miscellaneousData: abi.encode(pubkey), // RSA public key components
            proof: abi.encode(pA, pB, pC) // Groth16 proof components
         });

        expectedPubSignals = [
            2_018_721_414_038_404_820_327,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            6_632_353_713_085_157_925_504_008_443_078_919_716_322_386_156_160_602_218_536_961_028_046_468_237_192,
            2_202_380_611_270_802_977_810_424_243_055_429_330_904_378_876_663_812_534_622_621_703_884_867_377_135,
            0,
            180_891_110_264_973_503_160_226_225_538_030_206_223_858_091_522_603_795_023_666_265_748_100_181_059,
            173_532_502_901_810_909_445_165_194_544_006_900_992_761_359_126_983_071_590_425_318_149_531_518_018,
            82_064_499_489_411_320_061_695_384_032_176_580_663_311_076_544_288_210_199_978_613_071_800_383_044,
            6_845_541,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            8_080_113_390_678_316_609_048_973_094_352_283_823_282_558_465_605_593_816_562_416_100_021_989_554_450,
            0,
            2_107_195_391_459_410_975_264_579_855_291_297_887,
            2_562_632_063_603_354_817_278_035_230_349_645_235,
            1_868_388_447_387_859_563_289_339_873_373_526_818,
            2_159_353_473_203_648_408_714_805_618_210_333_973,
            351_789_365_378_952_303_483_249_084_740_952_389,
            659_717_315_519_250_910_761_248_850_885_776_286,
            1_321_773_785_542_335_225_811_636_767_147_612_036,
            258_646_249_156_909_342_262_859_240_016_844_424,
            644_872_192_691_135_519_287_736_182_201_377_504,
            174_898_460_680_981_733_302_111_356_557_122_107,
            1_068_744_134_187_917_319_695_255_728_151_595_132,
            1_870_792_114_609_696_396_265_442_109_963_534_232,
            8_288_818_605_536_063_568_933_922_407_756_344,
            1_446_710_439_657_393_605_686_016_190_803_199_177,
            2_256_068_140_678_002_554_491_951_090_436_701_670,
            518_946_826_903_468_667_178_458_656_376_730_744,
            3_222_036_726_675_473_160_989_497_427_257_757,
            9_533_142_343_906_178_599_764_761_089_706_585_145_829_492,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];

        return (command, expectedPubSignals);
    }
}
