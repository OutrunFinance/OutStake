// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./BaseScript.s.sol";
import { OutStakeRouter } from "../src/router/OutStakeRouter.sol";
import { IPrincipalToken } from "../src/core/YieldContracts/interfaces/IPrincipalToken.sol";
import { IOutrunDeployer, OutrunDeployer } from "../src/external/deployer/OutrunDeployer.sol";
import { IBlastGovernorable, BlastModeEnum } from "../src/external/blast/BlastGovernorable.sol";
import { OutrunBlastETHSY } from "../src/core/StandardizedYield/implementations/Blast/OutrunBlastETHSY.sol";
import { OutrunBlastUSDSY } from "../src/core/StandardizedYield/implementations/Blast/OutrunBlastUSDSY.sol";
import { OutrunPositionOptionTokenOnBlast } from "../src/core/Position/OutrunPositionOptionTokenOnBlast.sol";
import { OutrunERC4626YieldTokenOnBlast } from "../src/core/YieldContracts/OutrunERC4626YieldTokenOnBlast.sol";
import { OutrunPrincipalTokenOnBlast } from "../src/core/YieldContracts/OutrunPrincipalTokenOnBlast.sol";

contract OutstakeScriptOnBlast is BaseScript {
    address internal owner;
    address internal blastGovernor;
    address internal blastPoints;
    address internal pointsOperator;
    address internal revenuePool;
    address internal OUTRUN_DEPLOYER;
    uint256 internal protocolFeeRate;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        revenuePool = vm.envAddress("REVENUE_POOL");
        protocolFeeRate = vm.envUint("PROTOCOL_FEE_RATE");
        OUTRUN_DEPLOYER = vm.envAddress("OUTRUN_DEPLOYER");

        blastGovernor = vm.envAddress("BLAST_GOVERNOR");
        blastPoints = vm.envAddress("BLAST_POINTS");
        pointsOperator = vm.envAddress("POINTS_OPERATOR");

        deployOutStakeRouter(2);
        // supportBlastETH();
        // supportBlastUSD();
    }

    /**
     * Support Blast ETH 
     */
    function supportBlastETH() internal {
        address WETH = vm.envAddress("TESTNET_WETH");
 
        // SY
        OutrunBlastETHSY SY_BETH = new OutrunBlastETHSY(
            WETH,
            owner,
            blastGovernor,
            blastPoints,
            pointsOperator
        );
        address BETHSYAddress = address(SY_BETH);

        // PT
        OutrunPrincipalTokenOnBlast PT_BETH = new OutrunPrincipalTokenOnBlast(
            "Outrun BETH Principal Token",
            "PT-BETH",
            18,
            owner,
            blastGovernor
        );
        address BETHPTAddress = address(PT_BETH);
        
        // YT
        OutrunERC4626YieldTokenOnBlast YT_BETH = new OutrunERC4626YieldTokenOnBlast(
            "Outrun Blast ETH Yield Token",
            "YT-BETH",
            18,
            owner, 
            blastGovernor, 
            revenuePool, 
            protocolFeeRate
        );
        address BETHYTAddress = address(YT_BETH);

        // POT
        OutrunPositionOptionTokenOnBlast POT_BETH = new OutrunPositionOptionTokenOnBlast(
            owner,
            blastGovernor,
            "Blast ETH Position Option Token",
            "POT-BETH",
            18,
            0,
            protocolFeeRate,
            revenuePool,
            BETHSYAddress,
            BETHPTAddress,
            BETHYTAddress
        );
        POT_BETH.setLockupDuration(1, 365);
        address BETHPOTAddress = address(POT_BETH);

        IPrincipalToken(PT_BETH).initialize(BETHPOTAddress);
        YT_BETH.initialize(BETHSYAddress, BETHPOTAddress);

        // IBlastGovernorable(SY_BETH).configure(BlastModeEnum.YieldMode.CLAIMABLE, BlastModeEnum.GasMode.CLAIMABLE);
        // IBlastGovernorable(PT_BETH).configure(BlastModeEnum.YieldMode.VOID, BlastModeEnum.GasMode.CLAIMABLE);
        // IBlastGovernorable(YT_BETH).configure(BlastModeEnum.YieldMode.VOID, BlastModeEnum.GasMode.CLAIMABLE);
        // IBlastGovernorable(POT_BETH).configure(BlastModeEnum.YieldMode.VOID, BlastModeEnum.GasMode.CLAIMABLE);

        console.log("SY_BETH deployed on %s", BETHSYAddress);
        console.log("PT_BETH deployed on %s", BETHPTAddress);
        console.log("YT_BETH deployed on %s", BETHYTAddress);
        console.log("POT_BETH deployed on %s", BETHPOTAddress);
    }

    /**
     * Support USDB 
     */
    function supportBlastUSD() internal {
        address USDB = vm.envAddress("TESTNET_USDB");

        // SY
        OutrunBlastUSDSY SY_USDB = new OutrunBlastUSDSY(
            USDB,
            owner,
            blastGovernor,
            blastPoints,
            pointsOperator
        );
        address USDBSYAddress = address(SY_USDB);

        // PT
        OutrunPrincipalTokenOnBlast PT_USDB = new OutrunPrincipalTokenOnBlast(
            "Outrun USDB Principal Token",
            "PT-USDB",
            18,
            owner,
            blastGovernor
        );
        address USDBPTAddress = address(PT_USDB);
        
        // YT
        OutrunERC4626YieldTokenOnBlast YT_USDB = new OutrunERC4626YieldTokenOnBlast(
            "Outrun Blast USD Yield Token",
            "YT-USDB",
            18,
            owner, 
            blastGovernor, 
            revenuePool, 
            protocolFeeRate
        );
        address USDBYTAddress = address(YT_USDB);

        // POT
        OutrunPositionOptionTokenOnBlast POT_USDB = new OutrunPositionOptionTokenOnBlast(
            owner,
            blastGovernor,
            "Blast USD Position Option Token",
            "POT-BETH",
            18,
            0,
            protocolFeeRate,
            revenuePool,
            USDBSYAddress,
            USDBPTAddress,
            USDBYTAddress
        );
        POT_USDB.setLockupDuration(1, 365);
        address USDBPOTAddress = address(POT_USDB);

        IPrincipalToken(PT_USDB).initialize(USDBPOTAddress);
        YT_USDB.initialize(USDBSYAddress, USDBPOTAddress);

        // IBlastGovernorable(SY_USDB).configure(BlastModeEnum.YieldMode.CLAIMABLE, BlastModeEnum.GasMode.CLAIMABLE);
        // IBlastGovernorable(PT_USDB).configure(BlastModeEnum.YieldMode.VOID, BlastModeEnum.GasMode.CLAIMABLE);
        // IBlastGovernorable(YT_USDB).configure(BlastModeEnum.YieldMode.VOID, BlastModeEnum.GasMode.CLAIMABLE);
        // IBlastGovernorable(POT_USDB).configure(BlastModeEnum.YieldMode.VOID, BlastModeEnum.GasMode.CLAIMABLE);

        console.log("SY_USDB deployed on %s", USDBSYAddress);
        console.log("PT_USDB deployed on %s", USDBPTAddress);
        console.log("YT_USDB deployed on %s", USDBYTAddress);
        console.log("POT_USDB deployed on %s", USDBPOTAddress);
    }

    function deployOutStakeRouter(uint256 nonce) internal {
        bytes32 salt = keccak256(abi.encodePacked("OutStakeRouter", nonce));
        bytes memory creationCode = abi.encodePacked(type(OutStakeRouter).creationCode);
        address outStakeRouterAddr = IOutrunDeployer(OUTRUN_DEPLOYER).deploy(salt, creationCode);

        console.log("OutStakeRouter deployed on %s", outStakeRouterAddr);
    }
}