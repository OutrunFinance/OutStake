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
    address internal owner;
    address internal gasManager;
    address internal revenuePool;
    address internal blastPoints;
    address internal operator;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        revenuePool = vm.envAddress("REVENUE_POOL");
        gasManager = vm.envAddress("GAS_MANAGER");
        blastPoints = vm.envAddress("BLAST_POINTS");
        operator = vm.envAddress("OPERATOR");
        
        deployETH();
        deployUSDB();
    }

    function deployETH() internal {

        RETH reth = new RETH(owner, gasManager);
        address rethAddress = address(reth);

        PETH peth = new PETH(owner, gasManager);
        address pethAddress = address(peth);

        REY rey = new REY(owner, gasManager);
        address reyAddress = address(rey);

        OutETHVault vault = new OutETHVault(owner, gasManager, rethAddress, blastPoints);
        address vaultAddress = address(vault);

        RETHStakeManager stakeManager = new RETHStakeManager(
            owner,
            gasManager,
            rethAddress,
            pethAddress,
            reyAddress
        );
        address stakeAddress = address(stakeManager);
        
        // vault.initialize(operator, stakeAddress, revenuePool, 100, 15, 5);
        stakeManager.initialize(vaultAddress, 30, 7, 365);
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
        RUSD rusd = new RUSD(owner, gasManager);
        address rusdAddress = address(rusd);

        PUSD pusd = new PUSD(owner, gasManager);
        address pusdAddress = address(pusd);

        RUY ruy = new RUY(owner, gasManager);
        address ruyAddress = address(ruy);

        OutUSDBVault vault = new OutUSDBVault(owner, gasManager, rusdAddress, blastPoints);
        address vaultAddress = address(vault);

        RUSDStakeManager stakeManager = new RUSDStakeManager(
            owner, 
            gasManager,
            rusdAddress,
            pusdAddress,
            ruyAddress
        );
        address stakeAddress = address(stakeManager);

        vault.initialize(operator, stakeAddress, revenuePool, 100, 15, 5);
        stakeManager.initialize(vaultAddress, 30, 7, 365);
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