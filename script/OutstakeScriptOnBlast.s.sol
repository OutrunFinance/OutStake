// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.26;

// import "./BaseScript.s.sol";
// import "../src/core/Position/OutrunPositionOptionTokenOnBlast.sol";
// import "../src/core/YieldContracts/OutrunERC4626YieldTokenOnBlast.sol";
// import "../src/core/YieldContracts/universalPrincipalToken/UniversalPrincipalToken.sol";
// import "../src/core/StandardizedYield/implementations/Blast/OutrunBlastETHSY.sol";
// import "../src/core/StandardizedYield/implementations/Blast/OutrunBlastUSDSY.sol";

// contract OutstakeScriptOnBlast is BaseScript {
//     address internal owner;
//     address internal gasManager;
//     address internal blastPoints;
//     address internal pointsOperator;
//     address internal revenuePool;
//     uint256 internal protocolFeeRate;

//     function run() public broadcaster {
//         owner = vm.envAddress("OWNER");
//         gasManager = vm.envAddress("GAS_MANAGER");
//         blastPoints = vm.envAddress("BLAST_POINTS");
//         pointsOperator = vm.envAddress("POINTS_OPERATOR");
//         revenuePool = vm.envAddress("REVENUE_POOL");
//         protocolFeeRate = vm.envUint("PROTOCOL_FEE_RATE");

//         supportBlastETH();
//     }

//     /**
//      * Support Blast ETH 
//      */
//     function supportBlastETH() internal {
//         address WETH = vm.envAddress("TESTNET_WETH");
//         address nrETH = vm.envAddress("TESTNET_NRETH");

//         // Universal PT
//         UniversalPrincipalToken UETH = new UniversalPrincipalToken(
//             owner,
//             "Universal ETH Principal Token",
//             "UETH",
//             18
//         );
//         address UETHAddress = address(UETH);

//         // SY
//         OutrunBlastETHSY SY_BETH = new OutrunBlastETHSY(
//             WETH,
//             nrETH,
//             owner,
//             gasManager,
//             blastPoints,
//             pointsOperator
//         );
//         address BETHSYAddress = address(SY_BETH);
        
//         // YT
//         OutrunERC4626YieldTokenOnBlast YT_BETH = new OutrunERC4626YieldTokenOnBlast(
//             "Outrun Blast ETH Yield Token",
//             "YT-BETH",
//             18,
//             owner, 
//             gasManager, 
//             revenuePool, 
//             protocolFeeRate
//         );
//         address BETHYTAddress = address(YT_BETH);

//         // POT
//         OutrunPositionOptionTokenOnBlast POT_BETH = new OutrunPositionOptionTokenOnBlast(
//             owner,
//             gasManager,
//             "Blast ETH Position Option Token",
//             "POT-BETH",
//             18,
//             0,
//             protocolFeeRate,
//             revenuePool,
//             BETHSYAddress,
//             UETHAddress,
//             BETHYTAddress
//         );
//         POT_BETH.setLockupDuration(1, 365);
//         address BETHPOTAddress = address(POT_BETH);

//         UETH.setAuthList(BETHPOTAddress, true);
//         YT_BETH.initialize(BETHSYAddress, BETHPOTAddress);

//         console.log("Universal PT UETH deployed on %s", UETHAddress);
//         console.log("SY_BETH deployed on %s", BETHSYAddress);
//         console.log("YT_BETH deployed on %s", BETHYTAddress);
//         console.log("POT_BETH deployed on %s", BETHPOTAddress);
//     }

//     /**
//      * Support USDB 
//      */
//     function supportUSDB() internal {
//         address USDB = vm.envAddress("TESTNET_USDB");
//         address nrUSDB = vm.envAddress("TESTNET_NRUSDB");

//         // Universal PT
//         UniversalPrincipalToken UUSD = new UniversalPrincipalToken(
//             owner,
//             "Universal USD Principal Token",
//             "UUSD",
//             18
//         );
//         address UUSDAddress = address(UUSD);

//         // SY
//         OutrunBlastUSDSY SY_USDB = new OutrunBlastUSDSY(
//             USDB,
//             nrUSDB,
//             owner,
//             gasManager,
//             blastPoints,
//             pointsOperator
//         );
//         address USDBSYAddress = address(SY_USDB);
        
//         // YT
//         OutrunERC4626YieldTokenOnBlast YT_USDB = new OutrunERC4626YieldTokenOnBlast(
//             "Outrun Blast USD Yield Token",
//             "YT-USDB",
//             18,
//             owner, 
//             gasManager, 
//             revenuePool, 
//             protocolFeeRate
//         );
//         address USDBYTAddress = address(YT_USDB);

//         // POT
//         OutrunPositionOptionTokenOnBlast POT_USDB = new OutrunPositionOptionTokenOnBlast(
//             owner,
//             gasManager,
//             "Blast USD Position Option Token",
//             "POT-BETH",
//             18,
//             0,
//             protocolFeeRate,
//             revenuePool,
//             USDBSYAddress,
//             UUSDAddress,
//             USDBYTAddress
//         );
//         POT_USDB.setLockupDuration(1, 365);
//         address USDBPOTAddress = address(POT_USDB);

//         UUSD.setAuthList(USDBPOTAddress, true);
//         YT_USDB.initialize(USDBSYAddress, USDBPOTAddress);

//         console.log("Universal PT UUSD deployed on %s", UUSDAddress);
//         console.log("SY_USDB deployed on %s", USDBSYAddress);
//         console.log("YT_USDB deployed on %s", USDBYTAddress);
//         console.log("POT_USDB deployed on %s", USDBPOTAddress);
//     }
// }