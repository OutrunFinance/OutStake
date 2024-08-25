// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./BaseScript.s.sol";
import "../src/token/slisBNB/OSlisBNB.sol";
import "../src/token/slisBNB/YSlisBNB.sol";
import "../src/stake/ListaBNBStakeManager.sol";


contract OutstakeScript is BaseScript {
    address internal owner;
    address internal slisBNB;
    address internal revenuePool;
    address internal listaStakeManager;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        slisBNB = vm.envAddress("SLISBNB");
        revenuePool = vm.envAddress("REVENUE_POOL");
        listaStakeManager = vm.envAddress("LISTA_STAKE_MANAGER");
        
        deploySlisBNB();
    }

    function deploySlisBNB() internal {
        OSlisBNB oslisBNB = new OSlisBNB(owner);
        address oslisBNBAddress = address(oslisBNB);

        YSlisBNB yslisBNB = new YSlisBNB(owner);
        address yslisBNBAddress = address(yslisBNB);

        ListaBNBStakeManager stakeManager = new ListaBNBStakeManager(
            owner, 
            slisBNB,
            oslisBNBAddress, 
            yslisBNBAddress,
            listaStakeManager,
            ""
        );
        address stakeManagerAddress = address(stakeManager);

        stakeManager.initialize(
            revenuePool,
            500,    // protocolFee: 5%
            2000,   // burnedYTFee: 20%
            50,     // forceUnstakeFee: 0.5%
            7,      // minLockupDays: 7
            365,    // maxLockupDays: 365
            20,     // flashLoan providerFeeRate: 0.2%
            10      // flashLoan protocolFeeRate: 0.1%
        );
        oslisBNB.initialize(stakeManagerAddress);
        yslisBNB.initialize(stakeManagerAddress);

        console.log("oslisBNB deployed on %s", oslisBNBAddress);
        console.log("yslisBNB deployed on %s", yslisBNBAddress);
        console.log("ListaBNBStakeManager deployed on %s", stakeManagerAddress);
    }
}