//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IRETHYieldPool} from "./interfaces/IRETHYieldPool.sol";
import {IRETH} from "../token/ETH/interfaces/IRETH.sol";
import {IREYT} from "../token/ETH/interfaces/IREYT.sol";

/**
 * @title RETH Yield Pool
 */
contract RETHYieldPool is IRETHYieldPool {
    using SafeERC20 for IERC20;

    address public immutable rETH;
    address public immutable rEYT;

    /**
     * @param _rETH - Address of RETH Token
     * @param _rEYT - Address of REYT Token
     */
    constructor(address _rETH, address _rEYT) {
        rETH = _rETH;
        rEYT = _rEYT;
    }

    /**
     * @dev Allows user burn REYT to  withdraw yield
     * @param amountInREYT - Amount of REYT
     */
    function withdraw(uint256 amountInREYT) public override {
        require(amountInREYT > 0, "Invalid Amount");

        address user = msg.sender;
        IREYT(rEYT).burn(user, amountInREYT);

        uint256 _yieldAmount = Math.mulDiv(
            IRETH(rETH).balanceOf(address(this)),
            amountInREYT,
            IREYT(rEYT).totalSupply()
        );
        IERC20(rETH).safeTransfer(user, _yieldAmount);

        emit Withdraw(user, amountInREYT, _yieldAmount);
    }

    receive() external payable {}
}