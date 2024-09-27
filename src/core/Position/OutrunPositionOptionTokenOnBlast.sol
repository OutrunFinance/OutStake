//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "./OutrunPositionOptionToken.sol";
import "../../external/blast/GasManagerable.sol";

/**
 * @title Outrun Position Option Token On Blast
 */
contract OutrunPositionOptionTokenOnBlast is OutrunPositionOptionToken, GasManagerable {
    constructor(
        address owner_,
        address gasManager_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 minStake_,
        uint256 protocolFeeRate_,
        address revenuePool_,
        address _SY,
        address _PT,
        address _YT
    ) OutrunPositionOptionToken(
        owner_, 
        name_, 
        symbol_, 
        decimals_, 
        minStake_, 
        protocolFeeRate_, 
        revenuePool_, 
        _SY, 
        _PT, 
        _YT
    ) GasManagerable(gasManager_) {
    }
}
