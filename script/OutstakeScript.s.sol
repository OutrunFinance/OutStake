// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/token/ETH/RETH.sol";
import "../src/token/ETH/PETH.sol";
import "../src/token/ETH/REY.sol";
import "../src/token/USDB/RUSD.sol";
import "../src/token/USDB/PUSD.sol";
import "../src/token/USDB/RUY.sol";
import "../src/stake/RETHStakeManager.sol";
import "../src/stake/RUSDStakeManager.sol";
import "../src/vault/OutETHVault.sol";
import "../src/vault/OutUSDBVault.sol";

contract OutstakeScript is BaseScript {
    function run() public broadcaster {
        deployETH();
        deployUSDB();
    }

    function deployETH() internal {
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

        // vault.initialize(stakeAddress, 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, 100, 15, 5);
        reth.initialize(vaultAddress);
        peth.initialize(stakeAddress);
        rey.initialize(stakeAddress);

        console.log("RETH deployed on %s", rethAddress);
        console.log("PETH deployed on %s", pethAddress);
        console.log("REY deployed on %s", reyAddress);
        console.log("OutETHVault deployed on %s", vaultAddress);
        console.log("RETHStakeManager deployed on %s", stakeAddress);
    }

    function deployUSDB() internal {
        RUSD rusd = new RUSD(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        address rusdAddress = address(rusd);

        PUSD pusd = new PUSD(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        address pusdAddress = address(pusd);

        RUY ruy = new RUY(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        address ruyAddress = address(ruy);

        OutUSDBVault vault = new OutUSDBVault(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, rusdAddress);
        address vaultAddress = address(vault);

        RUSDStakeManager stakeManager = new RUSDStakeManager(
            0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8,
            rusdAddress,
            pusdAddress,
            ruyAddress
        );
        stakeManager.initialize(vaultAddress, 30, 7, 365);
        address stakeAddress = address(stakeManager);

        // vault.initialize(stakeAddress, 0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, 100, 15, 5);
        rusd.initialize(vaultAddress);
        pusd.initialize(stakeAddress);
        ruy.initialize(stakeAddress);

        console.log("RUSD deployed on %s", rusdAddress);
        console.log("PUSD deployed on %s", pusdAddress);
        console.log("RUY deployed on %s", ruyAddress);
        console.log("OutUSDBVault deployed on %s", vaultAddress);
        console.log("RUSDStakeManager deployed on %s", stakeAddress);
    }
}