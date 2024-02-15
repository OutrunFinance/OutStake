//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IRUSDYieldPool} from "./interfaces/IRUSDYieldPool.sol";
import {IRUSD} from "../token/USDB/interfaces/IRUSD.sol";
import {IRUYT} from "../token/USDB/interfaces/IRUYT.sol";

/**
 * @title RUSD Yield Pool
 */
contract RUSDYieldPool is IRUSDYieldPool {
    using SafeERC20 for IERC20;

    address public immutable rUSD;
    address public immutable rUYT;

    /**
     * @param _rUSD - Address of RUSD Token
     * @param _rUYT - Address of RUYT Token
     */
    constructor(address _rUSD, address _rUYT) {
        rUSD = _rUSD;
        rUYT = _rUYT;
    }

    /**
     * @dev Allows user burn RUYT to  withdraw yield
     * @param amountInRUYT - Amount of RUYT
     */
    function withdraw(uint256 amountInRUYT) public override {
        require(amountInRUYT > 0, "Invalid Amount");

        address user = msg.sender;
        IRUYT(rUYT).burn(user, amountInRUYT);

        uint256 _yieldAmount = Math.mulDiv(
            IRUSD(rUSD).balanceOf(address(this)),
            amountInRUYT,
            IRUYT(rUYT).totalSupply()
        );
        IERC20(rUSD).safeTransfer(user, _yieldAmount);

        emit Withdraw(user, amountInRUYT, _yieldAmount);
    }

    receive() external payable {}
}