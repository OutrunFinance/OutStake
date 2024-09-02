// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./BaseScript.s.sol";
import "../src/core/position/OutrunPositionOptionToken.sol";
import "../src/core/yield/implementations/Lista/OutrunSlisBNBSY.sol";
import "../src/core/yield/implementations/Lista/OutrunSlisBNBYieldToken.sol";
import "../src/core/yield/universalPrincipalToken/UniversalBNBPrincipalToken.sol";

contract OutstakeScript is BaseScript {
    address internal owner;
    address internal slisBNB;
    address internal revenuePool;
    address internal listaBNBStakeManager;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        slisBNB = vm.envAddress("SLISBNB");
        revenuePool = vm.envAddress("REVENUE_POOL");
        listaBNBStakeManager = vm.envAddress("LISTA_BNB_STAKE_MANAGER");
        
        deploySlisBNB();
    }

    function deploySlisBNB() internal {
        // Universal PT
        UniversalBNBPrincipalToken UBNB = new UniversalBNBPrincipalToken(owner);
        address UBNBAddress = address(UBNB);

        // SY
        OutrunSlisBNBSY SY_SLISBNB = new OutrunSlisBNBSY(owner, slisBNB, listaBNBStakeManager);
        address slisBNBSYAddress = address(SY_SLISBNB);
        
        // YT
        OutrunSlisBNBYieldToken YT_SLISBNB = new OutrunSlisBNBYieldToken(owner, revenuePool, 500);
        address slisBNBYTAddress = address(YT_SLISBNB);

        // POT
        OutrunPositionOptionToken POT_SLISBNB = new OutrunPositionOptionToken(
            owner,
            "SlisBNB Position Option Token",
            "POT-slisBNB",
            18,
            1e17,
            slisBNBSYAddress,
            UBNBAddress,
            slisBNBYTAddress
        );
        POT_SLISBNB.setLockupDuration(30, 365);
        address slisBNBPOTAddress = address(POT_SLISBNB);

        YT_SLISBNB.initialize(slisBNBSYAddress, slisBNBPOTAddress);

        console.log("Universal PT UBNB deployed on %s", UBNBAddress);
        console.log("SY_SLISBNB deployed on %s", slisBNBSYAddress);
        console.log("YT_SLISBNB deployed on %s", slisBNBYTAddress);
        console.log("POT_SLISBNB deployed on %s", slisBNBPOTAddress);
    }
}