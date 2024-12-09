// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import "./BaseScript.s.sol";
import { OutStakeRouter } from "../src/router/OutStakeRouter.sol";
import { IOutrunDeployer, OutrunDeployer } from "../src/external/deployer/OutrunDeployer.sol";
import { IListaBNBStakeManager } from "../src/external/lista/IListaBNBStakeManager.sol";
import { OutrunPositionOptionToken } from "../src/core/Position/OutrunPositionOptionToken.sol";
import { IPrincipalToken, OutrunPrincipalToken } from "../src/core/YieldContracts/OutrunPrincipalToken.sol";
import { IYieldToken } from "../src/core/YieldContracts/interfaces/IYieldToken.sol";
import { OutrunERC4626YieldToken } from "../src/core/YieldContracts/OutrunERC4626YieldToken.sol";
import { OutrunSlisBNBSY } from "../src/core/StandardizedYield/implementations/Lista/OutrunSlisBNBSY.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract OutstakeScript is BaseScript {
    address internal owner;
    address internal slisBNB;
    address internal revenuePool;
    address internal listaBNBStakeManager;
    address internal OUTRUN_DEPLOYER;
    uint256 internal protocolFeeRate;

    function run() public broadcaster {
        owner = vm.envAddress("OWNER");
        slisBNB = vm.envAddress("TESTNET_SLISBNB");
        revenuePool = vm.envAddress("REVENUE_POOL");
        listaBNBStakeManager = vm.envAddress("TESTNET_LISTA_BNB_STAKE_MANAGER");
        OUTRUN_DEPLOYER = vm.envAddress("OUTRUN_DEPLOYER");
        protocolFeeRate = vm.envUint("PROTOCOL_FEE_RATE");

        deployOutStakeRouter(2);
        // supportSlisBNB();
        // deployOutrunDeployer(1);
    }

    function deployOutrunDeployer(uint256 nonce) internal {
        bytes32 salt = keccak256(abi.encodePacked(owner, "OutrunDeployer", nonce));
        address outrunDeployerAddr = Create2.deploy(0, salt, abi.encodePacked(type(OutrunDeployer).creationCode, abi.encode(owner)));

        console.log("OutrunDeployer deployed on %s", outrunDeployerAddr);
    }

    function deployOutStakeRouter(uint256 nonce) internal {
        bytes32 salt = keccak256(abi.encodePacked("OutStakeRouter", nonce));
        bytes memory creationCode = abi.encodePacked(type(OutStakeRouter).creationCode);
        address outStakeRouterAddr = IOutrunDeployer(OUTRUN_DEPLOYER).deploy(salt, creationCode);

        console.log("OutStakeRouter deployed on %s", outStakeRouterAddr);
    }

    /**
     * Support slisBNB 
     */
    function supportSlisBNB() internal {
        // SY
        OutrunSlisBNBSY SY_SLISBNB = new OutrunSlisBNBSY(owner, slisBNB, IListaBNBStakeManager(listaBNBStakeManager));
        address slisBNBSYAddress = address(SY_SLISBNB);

        // PT
        OutrunPrincipalToken PT_SLISBNB = new OutrunPrincipalToken(
            "Outrun slisBNB Principal Token",
            "PT-slisBNB",
            18,
            owner
        );
        address slisBNBPTAddress = address(PT_SLISBNB);
        
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
            "Outrun SlisBNB Position Option Token",
            "POT-slisBNB",
            18,
            0,
            protocolFeeRate,
            revenuePool,
            slisBNBSYAddress,
            slisBNBPTAddress,
            slisBNBYTAddress
        );
        POT_SLISBNB.setLockupDuration(1, 365);
        address slisBNBPOTAddress = address(POT_SLISBNB);

        IPrincipalToken(slisBNBPTAddress).initialize(slisBNBPOTAddress);
        IYieldToken(slisBNBYTAddress).initialize(slisBNBSYAddress, slisBNBPOTAddress);

        console.log("SY_SLISBNB deployed on %s", slisBNBSYAddress);
        console.log("PT_SLISBNB deployed on %s", slisBNBPTAddress);
        console.log("YT_SLISBNB deployed on %s", slisBNBYTAddress);
        console.log("POT_SLISBNB deployed on %s", slisBNBPOTAddress);
    }

    function stringToBytes32(string memory str) public pure returns (bytes32) {
        bytes memory temp = bytes(str);
        require(temp.length <= 32, "String too long");
        bytes32 result;
        assembly {
            result := mload(add(str, 32))
        }
        return result;
    }
}