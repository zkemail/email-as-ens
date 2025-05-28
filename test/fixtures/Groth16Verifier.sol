// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r =
        21_888_242_871_839_275_222_246_405_745_257_275_088_548_364_400_416_034_343_698_204_186_575_808_495_617;
    // Base field size
    uint256 constant q =
        21_888_242_871_839_275_222_246_405_745_257_275_088_696_311_157_297_823_662_689_037_894_645_226_208_583;

    // Verification Key data
    uint256 constant alphax =
        20_491_192_805_390_485_299_153_009_773_594_534_940_189_261_866_228_447_918_068_658_471_970_481_763_042;
    uint256 constant alphay =
        9_383_485_363_053_290_200_918_347_156_157_836_566_562_967_994_039_712_273_449_902_621_266_178_545_958;
    uint256 constant betax1 =
        4_252_822_878_758_300_859_123_897_981_450_591_353_533_073_413_197_771_768_651_442_665_752_259_397_132;
    uint256 constant betax2 =
        6_375_614_351_688_725_206_403_948_262_868_962_793_625_744_043_794_305_715_222_011_528_459_656_738_731;
    uint256 constant betay1 =
        21_847_035_105_528_745_403_288_232_691_147_584_728_191_162_732_299_865_338_377_159_692_350_059_136_679;
    uint256 constant betay2 =
        10_505_242_626_370_262_277_552_901_082_094_356_697_409_835_680_220_590_971_873_171_140_371_331_206_856;
    uint256 constant gammax1 =
        11_559_732_032_986_387_107_991_004_021_392_285_783_925_812_861_821_192_530_917_403_151_452_391_805_634;
    uint256 constant gammax2 =
        10_857_046_999_023_057_135_944_570_762_232_829_481_370_756_359_578_518_086_990_519_993_285_655_852_781;
    uint256 constant gammay1 =
        4_082_367_875_863_433_681_332_203_403_145_435_568_316_851_327_593_401_208_105_741_076_214_120_093_531;
    uint256 constant gammay2 =
        8_495_653_923_123_431_417_604_973_247_489_272_438_418_190_587_263_600_148_770_280_649_306_958_101_930;
    uint256 constant deltax1 =
        7_548_383_171_302_710_111_172_340_506_459_731_004_452_108_252_889_431_901_957_342_632_956_443_675_277;
    uint256 constant deltax2 =
        17_823_723_667_032_638_488_089_734_048_430_293_846_076_460_466_631_831_179_339_020_400_923_924_397_441;
    uint256 constant deltay1 =
        16_103_161_902_585_107_286_175_127_150_509_450_883_738_350_728_224_206_026_391_441_579_157_260_137_941;
    uint256 constant deltay2 =
        7_249_892_538_270_091_879_496_023_412_313_215_171_786_689_398_761_624_317_958_826_926_009_583_931_468;

    uint256 constant IC0x =
        16_515_765_130_306_262_155_573_830_871_812_317_166_313_066_953_544_751_031_514_790_066_154_590_908_022;
    uint256 constant IC0y =
        17_990_861_552_260_786_408_082_101_905_083_830_716_439_856_505_890_511_737_384_213_949_734_315_116_930;

    uint256 constant IC1x =
        12_905_636_381_254_814_699_591_492_475_343_175_528_839_306_639_154_550_136_878_922_741_311_299_071_856;
    uint256 constant IC1y =
        288_986_413_890_323_927_168_454_472_434_001_432_658_377_379_928_641_702_296_977_571_491_875_792_656;

    uint256 constant IC2x =
        13_962_307_709_147_304_512_984_462_618_872_516_707_701_314_407_696_383_501_584_096_416_715_752_022_402;
    uint256 constant IC2y =
        4_980_539_138_289_041_629_981_944_133_155_801_516_015_284_172_909_047_356_816_187_418_694_947_627_230;

    uint256 constant IC3x =
        19_219_795_807_688_602_678_943_758_182_057_328_321_564_217_294_667_983_846_156_853_194_138_533_847_223;
    uint256 constant IC3y =
        17_339_862_161_300_997_728_533_180_996_597_268_631_387_084_596_472_198_405_568_540_816_973_126_622_274;

    uint256 constant IC4x =
        12_962_805_507_613_929_050_983_772_820_059_315_536_540_013_019_093_414_519_299_797_089_903_671_807_282;
    uint256 constant IC4y =
        13_567_847_281_245_537_955_037_957_643_625_246_617_731_700_977_880_320_820_037_475_690_049_945_629_132;

    uint256 constant IC5x =
        4_382_357_295_317_102_156_476_851_264_618_293_380_706_934_487_633_087_098_503_483_035_416_283_914_420;
    uint256 constant IC5y =
        18_155_960_097_544_610_318_939_375_348_711_202_014_795_645_666_062_243_759_502_756_023_770_496_929_667;

    uint256 constant IC6x =
        1_179_060_785_042_206_275_029_529_408_821_645_313_538_874_183_807_924_835_356_298_514_859_397_110_540;
    uint256 constant IC6y =
        7_706_598_424_838_448_182_118_393_751_881_848_657_808_788_761_034_289_212_070_170_293_150_929_978_934;

    uint256 constant IC7x =
        10_595_421_961_806_785_429_610_829_849_589_934_182_839_686_377_077_847_811_059_827_919_443_289_938_327;
    uint256 constant IC7y =
        8_165_494_106_060_388_241_498_245_159_123_546_008_786_301_861_166_917_959_714_424_424_631_646_400_799;

    uint256 constant IC8x =
        9_142_417_413_591_030_694_929_144_916_412_024_134_717_011_687_062_294_615_931_398_466_566_681_823_860;
    uint256 constant IC8y =
        12_714_035_366_369_323_416_116_821_716_366_472_981_679_727_957_737_653_665_070_025_559_893_070_630_877;

    uint256 constant IC9x =
        19_706_527_965_637_601_313_864_898_810_595_415_460_184_797_889_088_433_366_004_751_440_427_827_866_827;
    uint256 constant IC9y =
        20_958_745_739_878_983_684_921_912_237_369_833_918_858_776_611_581_100_182_746_833_919_875_581_106_756;

    uint256 constant IC10x =
        8_542_860_429_313_367_268_395_283_385_987_140_400_770_985_365_966_391_212_897_245_359_633_945_410_162;
    uint256 constant IC10y =
        11_541_691_607_086_623_226_090_634_953_549_247_131_302_416_417_022_936_644_641_274_821_358_765_444_881;

    uint256 constant IC11x =
        9_687_768_097_945_206_943_578_032_434_638_038_431_216_160_943_607_030_740_806_099_448_147_567_211_082;
    uint256 constant IC11y =
        19_253_480_151_887_940_592_509_642_529_242_668_581_651_168_291_318_226_697_141_157_287_434_569_838_119;

    uint256 constant IC12x =
        13_974_790_484_874_816_795_707_363_974_622_307_834_110_086_062_152_268_450_916_730_802_880_320_430_358;
    uint256 constant IC12y =
        18_657_517_928_077_661_360_731_730_154_495_938_064_310_917_500_332_167_327_772_850_258_834_828_879_270;

    uint256 constant IC13x =
        16_793_850_752_474_279_981_405_624_817_081_421_180_600_151_813_090_013_893_473_518_024_461_353_439_632;
    uint256 constant IC13y =
        7_702_545_518_914_052_214_010_970_676_524_391_425_211_060_445_686_647_721_862_754_654_068_166_608_824;

    uint256 constant IC14x =
        12_598_838_551_683_740_512_259_855_455_133_356_253_256_820_192_800_637_169_350_333_040_846_082_976_621;
    uint256 constant IC14y =
        17_513_002_525_265_901_416_793_860_478_684_254_853_093_534_477_792_892_562_897_948_310_088_733_497_448;

    uint256 constant IC15x =
        401_738_712_964_635_910_286_755_895_384_077_025_189_450_359_065_302_857_969_554_362_397_246_561_152;
    uint256 constant IC15y =
        14_690_301_065_342_065_077_938_803_061_768_766_309_305_590_175_587_557_174_184_833_148_203_341_544_549;

    uint256 constant IC16x =
        15_317_308_084_131_493_522_227_516_498_913_585_951_731_223_094_999_890_694_618_705_073_868_402_570_819;
    uint256 constant IC16y =
        3_738_923_719_999_283_738_721_759_149_042_335_753_767_940_781_287_701_005_107_376_941_750_973_377_923;

    uint256 constant IC17x =
        19_486_726_297_166_900_890_144_729_795_380_692_006_740_420_599_164_953_858_748_283_939_833_809_203_004;
    uint256 constant IC17y =
        21_669_575_185_870_315_875_965_428_652_450_784_521_797_990_203_417_828_604_161_925_607_508_771_125_178;

    uint256 constant IC18x =
        517_605_370_714_487_506_911_786_610_492_460_333_955_857_349_870_304_723_232_119_942_049_236_535_533;
    uint256 constant IC18y =
        11_983_658_381_565_194_241_672_713_770_966_572_576_251_970_489_720_164_258_228_592_350_808_408_907_102;

    uint256 constant IC19x =
        7_655_384_823_026_956_333_520_446_930_687_207_525_186_193_112_179_185_390_170_082_956_508_305_380_631;
    uint256 constant IC19y =
        20_960_135_401_083_366_466_971_660_092_013_725_782_776_473_923_018_811_929_100_822_538_873_092_918_383;

    uint256 constant IC20x =
        12_447_761_289_931_886_873_030_030_705_435_494_610_706_517_093_949_029_237_521_924_493_529_214_767_033;
    uint256 constant IC20y =
        4_300_065_070_347_996_788_728_860_865_380_729_468_823_758_564_264_622_078_769_188_121_612_232_172_204;

    uint256 constant IC21x =
        14_713_598_907_378_435_009_929_815_275_584_205_197_223_890_791_775_806_066_591_731_006_824_906_569_475;
    uint256 constant IC21y =
        8_114_758_346_400_764_609_684_928_416_961_699_263_301_382_415_061_002_566_425_478_244_227_341_238_052;

    uint256 constant IC22x =
        16_844_841_888_370_048_587_469_006_810_694_136_837_597_636_607_209_245_107_670_721_600_201_250_497_527;
    uint256 constant IC22y =
        13_784_758_984_735_831_812_194_974_443_773_054_058_865_789_479_326_141_563_722_300_244_969_561_560_556;

    uint256 constant IC23x =
        17_498_767_553_808_476_110_274_099_509_676_080_329_438_806_612_159_509_790_736_555_921_987_785_451_711;
    uint256 constant IC23y =
        21_703_013_771_390_715_795_728_631_464_655_274_535_710_020_385_304_201_690_129_153_666_592_348_460_576;

    uint256 constant IC24x =
        9_023_424_625_078_299_431_203_490_673_961_739_817_982_475_354_100_117_083_419_357_238_593_107_172_219;
    uint256 constant IC24y =
        16_324_085_098_163_795_601_289_122_251_501_423_422_804_395_648_683_606_875_209_583_648_496_920_535_008;

    uint256 constant IC25x =
        14_746_910_784_380_433_669_388_202_574_263_087_757_554_323_431_520_993_129_940_098_636_883_847_692_648;
    uint256 constant IC25y =
        9_390_972_866_586_080_808_404_369_032_778_895_959_374_003_551_555_611_995_373_443_494_512_131_646_744;

    uint256 constant IC26x =
        10_511_919_967_407_698_812_871_907_624_734_248_026_402_097_451_639_092_669_182_778_141_151_886_060_889;
    uint256 constant IC26y =
        16_797_720_107_390_645_394_834_611_862_911_703_218_904_851_717_477_102_842_245_253_077_492_575_186_113;

    uint256 constant IC27x =
        14_656_131_907_645_040_220_834_322_403_987_373_919_640_442_885_377_707_563_560_846_153_213_260_286_883;
    uint256 constant IC27y =
        16_110_665_846_953_213_128_714_614_109_085_745_566_577_709_661_949_403_462_577_304_830_870_099_102_368;

    uint256 constant IC28x =
        10_715_422_868_898_726_442_584_256_380_695_652_750_855_919_961_522_613_570_171_389_533_851_316_503_867;
    uint256 constant IC28y =
        12_718_003_475_009_332_765_423_327_086_094_137_698_552_761_614_609_752_654_667_029_914_485_449_014_503;

    uint256 constant IC29x =
        14_086_308_637_977_240_851_327_608_151_663_600_603_552_519_303_043_738_532_140_469_834_336_546_496_348;
    uint256 constant IC29y =
        17_445_047_827_602_943_092_363_214_573_968_781_093_866_497_875_118_294_823_958_571_459_790_569_149_410;

    uint256 constant IC30x =
        6_300_914_427_629_468_191_191_758_503_927_049_910_247_795_111_043_760_129_733_375_265_788_089_841_343;
    uint256 constant IC30y =
        6_365_134_802_598_548_556_263_238_084_913_699_071_057_716_533_306_741_409_508_817_184_307_713_042_693;

    uint256 constant IC31x =
        19_420_525_293_957_875_272_798_228_619_880_977_605_619_316_584_999_486_618_621_506_228_861_632_365_452;
    uint256 constant IC31y =
        15_396_338_670_652_957_720_490_859_609_529_209_977_539_931_906_368_994_063_498_228_667_603_356_513_243;

    uint256 constant IC32x =
        3_735_660_082_642_134_863_529_097_504_299_677_207_167_694_641_148_543_757_009_819_345_108_120_182_913;
    uint256 constant IC32y =
        17_642_218_178_566_247_974_674_503_580_896_806_681_535_905_353_698_101_793_656_344_570_128_806_139_943;

    uint256 constant IC33x =
        2_385_693_185_964_700_739_490_927_875_181_481_933_117_395_018_627_107_252_642_252_171_380_714_837_197;
    uint256 constant IC33y =
        13_101_582_499_149_397_717_123_291_308_259_341_429_578_804_996_349_399_251_589_191_814_904_799_197_769;

    uint256 constant IC34x =
        12_776_926_913_127_078_153_329_510_129_210_609_091_290_974_492_528_625_149_511_813_842_440_836_522_878;
    uint256 constant IC34y =
        850_001_700_243_680_598_271_026_400_555_882_878_961_248_517_827_958_417_473_846_349_600_495_370_922;

    uint256 constant IC35x =
        17_771_978_908_935_228_849_287_997_291_657_672_176_750_722_741_724_070_106_924_915_759_140_016_117_599;
    uint256 constant IC35y =
        3_757_304_090_488_782_319_033_378_901_812_631_272_404_732_913_410_902_900_557_995_946_777_106_661_789;

    uint256 constant IC36x =
        14_246_416_082_953_154_606_721_189_465_745_832_833_691_539_953_127_426_141_112_178_091_703_044_667_481;
    uint256 constant IC36y =
        1_113_308_669_774_143_401_999_515_742_175_056_909_099_028_877_005_455_676_582_182_555_969_575_663_494;

    uint256 constant IC37x =
        10_987_516_028_950_338_692_844_922_239_642_806_040_561_724_042_516_444_490_361_297_146_225_347_587_471;
    uint256 constant IC37y =
        13_822_739_308_216_253_532_026_206_502_628_606_209_983_529_019_095_860_124_978_985_844_205_005_499_943;

    uint256 constant IC38x =
        17_034_509_480_019_664_337_017_351_318_081_244_775_735_018_579_781_638_899_865_324_676_362_276_331_124;
    uint256 constant IC38y =
        10_685_053_644_812_663_718_647_067_286_151_935_853_020_938_941_751_600_944_614_798_725_923_854_443_525;

    uint256 constant IC39x =
        13_471_244_967_613_124_706_958_135_313_034_193_240_698_710_796_271_752_973_795_930_116_999_089_877_269;
    uint256 constant IC39y =
        8_962_872_455_083_451_472_045_251_702_062_274_740_330_765_855_293_320_540_206_676_737_119_289_088_257;

    uint256 constant IC40x =
        15_239_900_780_229_046_497_887_142_414_270_812_313_998_161_057_066_550_293_027_687_381_322_179_690_270;
    uint256 constant IC40y =
        18_991_848_932_388_822_449_756_463_276_781_575_795_236_437_606_273_000_434_778_070_476_113_756_459_679;

    uint256 constant IC41x =
        4_082_195_541_636_663_946_660_725_440_777_794_546_752_817_417_396_799_428_177_683_349_274_685_030_284;
    uint256 constant IC41y =
        13_977_001_406_412_840_962_618_273_933_562_546_662_683_063_427_918_244_544_573_632_969_252_617_223_337;

    uint256 constant IC42x =
        14_343_408_402_051_139_704_727_376_002_576_684_391_029_801_529_949_821_251_283_888_900_449_063_670_606;
    uint256 constant IC42y =
        7_858_557_568_934_588_864_530_903_689_006_468_558_621_493_906_412_520_873_241_007_164_018_609_864_257;

    uint256 constant IC43x =
        19_306_751_058_959_770_224_964_575_758_668_887_542_152_851_435_858_441_191_998_181_253_362_448_884_017;
    uint256 constant IC43y =
        8_513_049_096_115_519_170_067_775_817_800_824_940_312_691_873_577_951_918_827_827_628_702_487_739_701;

    uint256 constant IC44x =
        1_298_819_624_693_112_517_363_944_736_415_048_871_658_726_931_496_225_291_347_178_892_548_346_108_093;
    uint256 constant IC44y =
        17_799_648_244_095_055_464_243_888_599_631_130_945_226_582_827_479_385_741_517_998_885_039_672_775_187;

    uint256 constant IC45x =
        11_349_158_501_686_233_813_510_143_201_362_963_053_372_570_803_605_598_631_163_464_256_112_001_457_284;
    uint256 constant IC45y =
        1_453_616_552_172_979_072_023_012_608_217_561_478_368_082_165_452_524_337_386_101_794_601_166_959_579;

    uint256 constant IC46x =
        11_156_729_341_473_928_832_544_340_066_161_615_625_110_343_080_571_962_309_331_607_486_462_997_783_520;
    uint256 constant IC46y =
        7_258_439_294_615_972_436_725_170_286_637_747_901_364_106_160_709_281_706_377_866_417_387_045_614_450;

    uint256 constant IC47x =
        6_751_935_766_164_633_277_196_052_787_916_586_702_159_842_868_801_834_969_240_666_587_443_092_355_175;
    uint256 constant IC47y =
        13_400_796_821_870_320_812_338_762_491_350_817_010_941_083_142_015_819_321_995_000_339_418_040_369_136;

    uint256 constant IC48x =
        18_836_707_373_349_446_737_340_719_657_388_483_563_820_772_423_384_392_730_658_255_221_578_987_184_015;
    uint256 constant IC48y =
        15_701_406_223_005_098_744_326_207_639_745_284_965_871_274_789_457_108_365_246_473_195_582_205_360_695;

    uint256 constant IC49x =
        13_642_992_615_205_496_762_955_317_232_062_491_338_587_613_093_622_982_432_153_928_341_846_426_208_629;
    uint256 constant IC49y =
        1_403_781_305_462_196_253_753_129_326_434_717_834_153_274_088_938_458_636_055_811_056_577_061_516_357;

    uint256 constant IC50x =
        5_789_428_697_585_952_046_025_938_325_213_479_691_684_440_988_643_019_180_619_648_260_695_449_709_708;
    uint256 constant IC50y =
        4_685_054_264_590_820_902_354_641_160_702_327_730_673_515_332_809_618_317_208_222_164_932_293_625_307;

    uint256 constant IC51x =
        13_744_360_476_383_497_853_481_338_947_225_910_820_818_776_355_785_671_730_666_522_893_478_484_994_694;
    uint256 constant IC51y =
        1_145_329_326_030_936_498_443_610_360_549_965_404_622_391_476_858_680_278_747_507_795_702_985_334_612;

    uint256 constant IC52x =
        14_318_932_484_111_652_319_333_088_836_154_277_148_832_713_948_092_109_454_290_836_979_522_688_154_688;
    uint256 constant IC52y =
        17_918_799_828_794_389_680_851_519_912_634_017_899_109_099_497_887_920_303_595_035_497_147_439_117_817;

    uint256 constant IC53x =
        13_070_165_302_259_834_825_056_013_082_328_173_206_873_789_853_855_078_554_403_523_925_167_888_257_994;
    uint256 constant IC53y =
        1_484_397_399_000_775_440_567_263_788_852_464_319_850_007_991_229_010_858_830_012_410_297_897_694_352;

    uint256 constant IC54x =
        5_231_270_247_906_649_353_081_728_481_245_504_195_880_420_760_796_851_223_083_046_670_692_069_847_144;
    uint256 constant IC54y =
        7_663_802_896_579_649_572_537_631_634_033_805_052_522_699_661_913_066_223_552_159_605_080_891_208_442;

    uint256 constant IC55x =
        17_256_142_684_096_683_742_146_580_522_406_656_733_913_334_512_996_722_014_292_026_820_833_784_677_079;
    uint256 constant IC55y =
        21_544_725_521_871_551_521_438_918_698_848_792_691_850_346_447_769_784_386_814_078_502_412_126_578_418;

    uint256 constant IC56x =
        965_616_940_476_025_588_796_293_093_331_755_256_374_915_416_897_589_832_450_322_319_548_172_921_545;
    uint256 constant IC56y =
        1_594_901_823_449_403_793_827_904_921_875_928_255_934_268_770_434_429_346_575_246_323_473_989_210_640;

    uint256 constant IC57x =
        232_108_856_810_327_091_794_859_448_050_905_682_245_987_915_758_754_755_081_932_982_346_195_742_972;
    uint256 constant IC57y =
        7_000_809_976_682_786_305_449_067_600_540_687_010_590_075_122_294_746_885_802_759_206_631_802_850_143;

    uint256 constant IC58x =
        21_356_732_885_748_896_099_948_321_174_507_716_057_521_005_707_150_053_605_933_599_195_042_014_351_664;
    uint256 constant IC58y =
        129_791_484_227_379_273_680_496_729_934_773_898_070_164_339_104_954_329_415_435_673_386_800_616_846;

    uint256 constant IC59x =
        16_357_838_651_635_285_255_092_711_766_234_267_286_520_323_464_933_436_080_370_916_015_696_561_737_436;
    uint256 constant IC59y =
        2_514_949_325_587_149_718_504_489_386_567_853_242_331_507_580_056_615_330_339_441_556_587_621_882_389;

    uint256 constant IC60x =
        15_810_724_851_697_455_191_046_913_515_757_246_632_975_813_439_786_006_276_660_217_524_786_629_982_412;
    uint256 constant IC60y =
        1_284_129_700_249_718_081_529_699_137_153_491_995_555_332_892_332_312_410_593_713_034_258_920_240_434;

    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(
        uint256[2] calldata _pA,
        uint256[2][2] calldata _pB,
        uint256[2] calldata _pC,
        uint256[60] calldata _pubSignals
    )
        public
        view
        returns (bool)
    {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))

                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))

                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))

                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))

                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))

                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))

                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))

                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))

                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))

                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))

                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))

                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))

                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))

                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))

                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))

                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))

                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))

                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))

                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))

                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))

                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))

                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))

                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))

                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))

                g1_mulAccC(_pVk, IC35x, IC35y, calldataload(add(pubSignals, 1088)))

                g1_mulAccC(_pVk, IC36x, IC36y, calldataload(add(pubSignals, 1120)))

                g1_mulAccC(_pVk, IC37x, IC37y, calldataload(add(pubSignals, 1152)))

                g1_mulAccC(_pVk, IC38x, IC38y, calldataload(add(pubSignals, 1184)))

                g1_mulAccC(_pVk, IC39x, IC39y, calldataload(add(pubSignals, 1216)))

                g1_mulAccC(_pVk, IC40x, IC40y, calldataload(add(pubSignals, 1248)))

                g1_mulAccC(_pVk, IC41x, IC41y, calldataload(add(pubSignals, 1280)))

                g1_mulAccC(_pVk, IC42x, IC42y, calldataload(add(pubSignals, 1312)))

                g1_mulAccC(_pVk, IC43x, IC43y, calldataload(add(pubSignals, 1344)))

                g1_mulAccC(_pVk, IC44x, IC44y, calldataload(add(pubSignals, 1376)))

                g1_mulAccC(_pVk, IC45x, IC45y, calldataload(add(pubSignals, 1408)))

                g1_mulAccC(_pVk, IC46x, IC46y, calldataload(add(pubSignals, 1440)))

                g1_mulAccC(_pVk, IC47x, IC47y, calldataload(add(pubSignals, 1472)))

                g1_mulAccC(_pVk, IC48x, IC48y, calldataload(add(pubSignals, 1504)))

                g1_mulAccC(_pVk, IC49x, IC49y, calldataload(add(pubSignals, 1536)))

                g1_mulAccC(_pVk, IC50x, IC50y, calldataload(add(pubSignals, 1568)))

                g1_mulAccC(_pVk, IC51x, IC51y, calldataload(add(pubSignals, 1600)))

                g1_mulAccC(_pVk, IC52x, IC52y, calldataload(add(pubSignals, 1632)))

                g1_mulAccC(_pVk, IC53x, IC53y, calldataload(add(pubSignals, 1664)))

                g1_mulAccC(_pVk, IC54x, IC54y, calldataload(add(pubSignals, 1696)))

                g1_mulAccC(_pVk, IC55x, IC55y, calldataload(add(pubSignals, 1728)))

                g1_mulAccC(_pVk, IC56x, IC56y, calldataload(add(pubSignals, 1760)))

                g1_mulAccC(_pVk, IC57x, IC57y, calldataload(add(pubSignals, 1792)))

                g1_mulAccC(_pVk, IC58x, IC58y, calldataload(add(pubSignals, 1824)))

                g1_mulAccC(_pVk, IC59x, IC59y, calldataload(add(pubSignals, 1856)))

                g1_mulAccC(_pVk, IC60x, IC60y, calldataload(add(pubSignals, 1888)))

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))

                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)

                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F

            checkField(calldataload(add(_pubSignals, 0)))

            checkField(calldataload(add(_pubSignals, 32)))

            checkField(calldataload(add(_pubSignals, 64)))

            checkField(calldataload(add(_pubSignals, 96)))

            checkField(calldataload(add(_pubSignals, 128)))

            checkField(calldataload(add(_pubSignals, 160)))

            checkField(calldataload(add(_pubSignals, 192)))

            checkField(calldataload(add(_pubSignals, 224)))

            checkField(calldataload(add(_pubSignals, 256)))

            checkField(calldataload(add(_pubSignals, 288)))

            checkField(calldataload(add(_pubSignals, 320)))

            checkField(calldataload(add(_pubSignals, 352)))

            checkField(calldataload(add(_pubSignals, 384)))

            checkField(calldataload(add(_pubSignals, 416)))

            checkField(calldataload(add(_pubSignals, 448)))

            checkField(calldataload(add(_pubSignals, 480)))

            checkField(calldataload(add(_pubSignals, 512)))

            checkField(calldataload(add(_pubSignals, 544)))

            checkField(calldataload(add(_pubSignals, 576)))

            checkField(calldataload(add(_pubSignals, 608)))

            checkField(calldataload(add(_pubSignals, 640)))

            checkField(calldataload(add(_pubSignals, 672)))

            checkField(calldataload(add(_pubSignals, 704)))

            checkField(calldataload(add(_pubSignals, 736)))

            checkField(calldataload(add(_pubSignals, 768)))

            checkField(calldataload(add(_pubSignals, 800)))

            checkField(calldataload(add(_pubSignals, 832)))

            checkField(calldataload(add(_pubSignals, 864)))

            checkField(calldataload(add(_pubSignals, 896)))

            checkField(calldataload(add(_pubSignals, 928)))

            checkField(calldataload(add(_pubSignals, 960)))

            checkField(calldataload(add(_pubSignals, 992)))

            checkField(calldataload(add(_pubSignals, 1024)))

            checkField(calldataload(add(_pubSignals, 1056)))

            checkField(calldataload(add(_pubSignals, 1088)))

            checkField(calldataload(add(_pubSignals, 1120)))

            checkField(calldataload(add(_pubSignals, 1152)))

            checkField(calldataload(add(_pubSignals, 1184)))

            checkField(calldataload(add(_pubSignals, 1216)))

            checkField(calldataload(add(_pubSignals, 1248)))

            checkField(calldataload(add(_pubSignals, 1280)))

            checkField(calldataload(add(_pubSignals, 1312)))

            checkField(calldataload(add(_pubSignals, 1344)))

            checkField(calldataload(add(_pubSignals, 1376)))

            checkField(calldataload(add(_pubSignals, 1408)))

            checkField(calldataload(add(_pubSignals, 1440)))

            checkField(calldataload(add(_pubSignals, 1472)))

            checkField(calldataload(add(_pubSignals, 1504)))

            checkField(calldataload(add(_pubSignals, 1536)))

            checkField(calldataload(add(_pubSignals, 1568)))

            checkField(calldataload(add(_pubSignals, 1600)))

            checkField(calldataload(add(_pubSignals, 1632)))

            checkField(calldataload(add(_pubSignals, 1664)))

            checkField(calldataload(add(_pubSignals, 1696)))

            checkField(calldataload(add(_pubSignals, 1728)))

            checkField(calldataload(add(_pubSignals, 1760)))

            checkField(calldataload(add(_pubSignals, 1792)))

            checkField(calldataload(add(_pubSignals, 1824)))

            checkField(calldataload(add(_pubSignals, 1856)))

            checkField(calldataload(add(_pubSignals, 1888)))

            checkField(calldataload(add(_pubSignals, 1920)))

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}
