// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

abstract contract BaseScript is Script {
    address internal owner;
    address internal gasManager;
    address internal revenuePool;
    address internal blastPoints;
    address internal operator;

    uint256 internal privateKey;
    address internal deployer;
    string internal mnemonic;
    
    function setUp() public virtual {
        //mnemonic = vm.envString("MNEMONIC");
        privateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.envAddress("OWNER");
        revenuePool = vm.envAddress("REVENUE_POOL");
        gasManager = vm.envAddress("GAS_MANAGER");
        blastPoints = vm.envAddress("BLAST_POINTS");
        operator = vm.envAddress("OPERATOR");
        deployer = vm.rememberKey(privateKey);
    }

    // function saveContract(string memory network, string memory name, address addr) public {
    //   string memory json1 = "key";
    //   string memory finalJson =  vm.serializeAddress(json1, "address", addr);
    //   string memory dirPath = string.concat(string.concat("output/", network), "/");
    //   vm.writeJson(finalJson, string.concat(dirPath, string.concat(name, ".json"))); 
    // }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}