// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./BaseScript.s.sol";
import "../src/token/ETH/RETH.sol";
import "../src/token/ETH/REY.sol";
import "../src/yield/RETHYieldPool.sol";
import "../src/vault/OutETHVault.sol";

contract OutrunScript is BaseScript {
    function run() public broadcaster {
        RETH reth = new RETH(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);
        REY rey = new REY(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8);

        RETHYieldPool yieldPool = new RETHYieldPool(0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, address(reth), address(rey));
        OutETHVault vault = new OutETHVault(
            0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, 
            address(reth), 
            0x20ae1f29849E8392BD83c3bCBD6bD5301a6656F8, 
            address(yieldPool), 
            100);

        reth.setOutETHVault(address(vault));
        rey.setRETHYieldPool(address(yieldPool));

        console.log("RETH deployed on %s", address(reth));
        console.log("REY deployed on %s", address(rey));
        console.log("RETHYieldPool deployed on %s", address(yieldPool));
        console.log("OutETHVault deployed on %s", address(vault));
    }
}