//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IRETHYieldPool} from "./interfaces/IRETHYieldPool.sol";
import {IRETH} from "../token/ETH/interfaces/IRETH.sol";
import {IREY} from "../token/ETH/interfaces/IREY.sol";

/**
 * @title RETH Yield Pool
 */
contract RETHYieldPool is IRETHYieldPool {
    using SafeERC20 for IERC20;

    address public immutable rETH;
    address public immutable rey;

    /**
     * @param _rETH - Address of RETH Token
     * @param _rey - Address of REY Token
     */
    constructor(address _rETH, address _rey) {
        rETH = _rETH;
        rey = _rey;
    }

    /**
     * @dev Allows user burn REY to  withdraw yield
     * @param amountInREY - Amount of REY
     */
    function withdraw(uint256 amountInREY) external override {
        require(amountInREY > 0, "Invalid Amount");

        address user = msg.sender;
        IREY(rey).burn(user, amountInREY);

        uint256 _yieldAmount = Math.mulDiv(
            IRETH(rETH).balanceOf(address(this)),
            amountInREY,
            IREY(rey).totalSupply()
        );
        IERC20(rETH).safeTransfer(user, _yieldAmount);

        emit Withdraw(user, amountInREY, _yieldAmount);
    }

    receive() external payable {}
}