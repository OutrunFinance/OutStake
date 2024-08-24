// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BaseScript.s.sol";
import "../src/token/ETH/ORETH.sol";
import "../src/token/ETH/OSETH.sol";
import "../src/token/ETH/REY.sol";
import "../src/token/USDB/ORUSD.sol";
import "../src/token/USDB/OSUSD.sol";
import "../src/token/USDB/RUY.sol";
import "../src/stake/ORETHStakeManager.sol";
import "../src/stake/ORUSDStakeManager.sol";

contract OutstakeScript is BaseScript {
    address internal owner;
    address internal autoBot;
    address internal gasManager;
    address internal revenuePool;
    address internal blastPoints;
    address internal pointsOperator;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        autoBot = vm.envAddress("AUTO_BOT");
        revenuePool = vm.envAddress("REVENUE_POOL");
        gasManager = vm.envAddress("GAS_MANAGER");
        pointsOperator = vm.envAddress("POINTS_OPERATOR");
        
        
        //deployETH();
        deployUSDB();
    }

    function deployETH() internal {
        ORETH orETH = new ORETH(owner, gasManager, autoBot, revenuePool, pointsOperator, 1000, 15, 5);
        address orETHAddress = address(orETH);

        OSETH osETH = new OSETH(owner, gasManager);
        address osETHAddress = address(osETH);

        REY rey = new REY(owner, gasManager);
        address reyAddress = address(rey);

        ORETHStakeManager stakeManager = new ORETHStakeManager(
            owner,
            gasManager,
            orETHAddress,
            osETHAddress,
            reyAddress,
            ""
        );
        address stakeAddress = address(stakeManager);
        
        stakeManager.initialize(50, 2000, 7, 365);
        //orETH.initialize(stakeAddress);
        osETH.initialize(stakeAddress);
        rey.initialize(stakeAddress);

        console.log("ORETH deployed on %s", orETHAddress);
        console.log("OSETH deployed on %s", osETHAddress);
        console.log("REY deployed on %s", reyAddress);
        console.log("ORETHStakeManager deployed on %s", stakeAddress);
    }

    function deployUSDB() internal {
        ORUSD orUSD = new ORUSD(owner, gasManager, autoBot, revenuePool, pointsOperator, 1000, 15, 5);
        address orUSDAddress = address(orUSD);

        OSUSD osUSD = new OSUSD(owner, gasManager);
        address osUSDAddress = address(osUSD);

        RUY ruy = new RUY(owner, gasManager);
        address ruyAddress = address(ruy);

        ORUSDStakeManager stakeManager = new ORUSDStakeManager(
            owner, 
            gasManager,
            orUSDAddress,
            osUSDAddress,
            ruyAddress,
            ""
        );
        address stakeAddress = address(stakeManager);

        stakeManager.initialize(50, 2000, 7, 365);
        orUSD.initialize(stakeAddress);
        osUSD.initialize(stakeAddress);
        ruy.initialize(stakeAddress);

        console.log("ORUSD deployed on %s", orUSDAddress);
        console.log("OSUSD deployed on %s", osUSDAddress);
        console.log("RUY deployed on %s", ruyAddress);
        console.log("ORUSDStakeManager deployed on %s", stakeAddress);
    }
}