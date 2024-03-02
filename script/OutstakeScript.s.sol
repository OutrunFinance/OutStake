// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/token/ETH/RETH.sol";
import "../src/token/ETH/PETH.sol";
import "../src/token/ETH/REY.sol";
import "../src/stake/RETHStakeManager.sol";
import "../src/vault/OutETHVault.sol";

contract OutstakeScript is BaseScript {
    function run() public broadcaster {
        RETH reth = new RETH(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        address rethAddress = address(reth);

        PETH peth = new PETH(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        address pethAddress = address(peth);

        REY rey = new REY(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        address reyAddress = address(rey);

        OutETHVault vault = new OutETHVault(
            0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, 
            rethAddress, 
            0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, 
            1000);
        address vaultAddress = address(vault);

        RETHStakeManager stakeManager = new RETHStakeManager(
            0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8,
            rethAddress,
            pethAddress,
            reyAddress,
            vaultAddress,
            1000
        );
        address stakeAddress = address(stakeManager);

        vault.initialize();
        vault.setFlashLoanFee(15, 5);
        reth.setOutETHVault(vaultAddress);
        peth.setRETHStakeManager(stakeAddress);
        rey.setRETHStakeManager(stakeAddress);

        console.log("RETH deployed on %s", rethAddress);
        console.log("PETH deployed on %s", pethAddress);
        console.log("REY deployed on %s", reyAddress);
        console.log("OutETHVault deployed on %s", vaultAddress);
        console.log("RETHStakeManager deployed on %s", stakeAddress);
    }
}