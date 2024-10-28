// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./BaseScript.s.sol";
import "../src/router/OutStakeRouter.sol";
import "../src/external/lista/IListaBNBStakeManager.sol";
import "../src/core/Position/OutrunPositionOptionToken.sol";
import "../src/core/YieldContracts/OutrunERC4626YieldToken.sol";
import "../src/core/YieldContracts/universalPrincipalToken/UniversalPrincipalToken.sol";
import "../src/core/StandardizedYield/implementations/Lista/OutrunSlisBNBSY.sol";
import "../src/core/StandardizedYield/implementations/Blast/OutrunBlastETHSY.sol";

contract OutstakeScriptOnBNB is BaseScript {
    address internal owner;
    address internal slisBNB;
    address internal revenuePool;
    address internal listaBNBStakeManager;
    uint256 internal protocolFeeRate;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        slisBNB = vm.envAddress("TESTNET_SLISBNB");
        revenuePool = vm.envAddress("REVENUE_POOL");
        listaBNBStakeManager = vm.envAddress("TESTNET_LISTA_BNB_STAKE_MANAGER");
        protocolFeeRate = vm.envUint("PROTOCOL_FEE_RATE");

        deployRouter();
        supportSlisBNB();
    }

    /**
     * Deploy router 
     */
    function deployRouter() internal {
        // Router
        OutStakeRouter router = new OutStakeRouter();
        console.log("OutStakeRouter deployed on %s", address(router));
    }

    /**
     * Support slisBNB 
     */
    function supportSlisBNB() internal {
        // Universal PT
        UniversalPrincipalToken UBNB = new UniversalPrincipalToken(
            owner,
            "Universal BNB Principal Token",
            "UBNB",
            18
        );
        address UBNBAddress = address(UBNB);

        // SY
        OutrunSlisBNBSY SY_SLISBNB = new OutrunSlisBNBSY(owner, slisBNB, IListaBNBStakeManager(listaBNBStakeManager));
        address slisBNBSYAddress = address(SY_SLISBNB);
        
        // YT
        OutrunERC4626YieldToken YT_SLISBNB = new OutrunERC4626YieldToken(
            "Outrun slisBNB Yield Token",
            "YT-slisBNB",
            18,
            owner, 
            revenuePool, 
            protocolFeeRate
        );
        address slisBNBYTAddress = address(YT_SLISBNB);

        // POT
        OutrunPositionOptionToken POT_SLISBNB = new OutrunPositionOptionToken(
            owner,
            "SlisBNB Position Option Token",
            "POT-slisBNB",
            18,
            0,
            protocolFeeRate,
            revenuePool,
            slisBNBSYAddress,
            UBNBAddress,
            slisBNBYTAddress
        );
        POT_SLISBNB.setLockupDuration(1, 365);
        address slisBNBPOTAddress = address(POT_SLISBNB);

        UBNB.setAuthList(slisBNBPOTAddress, true);
        YT_SLISBNB.initialize(slisBNBSYAddress, slisBNBPOTAddress);

        console.log("Universal PT UBNB deployed on %s", UBNBAddress);
        console.log("SY_SLISBNB deployed on %s", slisBNBSYAddress);
        console.log("YT_SLISBNB deployed on %s", slisBNBYTAddress);
        console.log("POT_SLISBNB deployed on %s", slisBNBPOTAddress);
    }
}