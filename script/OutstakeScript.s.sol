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

        OutETHVault vault = new OutETHVault(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, rethAddress);
        address vaultAddress = address(vault);

        RETHStakeManager stakeManager = new RETHStakeManager(
            0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8,
            rethAddress,
            pethAddress,
            reyAddress
        );
        stakeManager.initialize(vaultAddress, 30, 7, 365);
        address stakeAddress = address(stakeManager);

        vault.initialize(stakeAddress, 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, 100, 15, 5);
        reth.initialize(vaultAddress);
        peth.initialize(stakeAddress);
        rey.initialize(stakeAddress);

        console.log("RETH deployed on %s", rethAddress);
        console.log("PETH deployed on %s", pethAddress);
        console.log("REY deployed on %s", reyAddress);
        console.log("OutETHVault deployed on %s", vaultAddress);
        console.log("RETHStakeManager deployed on %s", stakeAddress);
    }
}