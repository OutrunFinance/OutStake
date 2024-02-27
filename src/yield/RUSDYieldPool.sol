//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../vault/interfaces/IOutUSDBVault.sol";
import {IRUSDYieldPool} from "./interfaces/IRUSDYieldPool.sol";
import {IRUSD} from "../token/USDB/interfaces/IRUSD.sol";
import {IRUY} from "../token/USDB/interfaces/IRUY.sol";

/**
 * @title RUSD Yield Pool
 */
contract RUSDYieldPool is IRUSDYieldPool, Ownable {
    using SafeERC20 for IERC20;

    address public immutable rUSD;
    address public immutable ruy;
    address public outUSDBVault;

    /**
     * @param _rUSD - Address of RUSD Token
     * @param _ruy - Address of RUY Token
     */
    constructor(address _owner, address _rUSD, address _ruy) Ownable(_owner) {
        rUSD = _rUSD;
        ruy = _ruy;
    }

    /**
     * @dev Allows user burn RUY to  withdraw yield
     * @param amountInRUY - Amount of RUY
     */
    function withdraw(uint256 amountInRUY) external override {
        require(amountInRUY > 0, "Invalid Amount");

        address user = msg.sender;

        IOutUSDBVault(outUSDBVault).claimUSDBYield();
        uint256 _yieldAmount = Math.mulDiv(
            IRUSD(rUSD).balanceOf(address(this)),
            amountInRUY,
            IRUY(ruy).totalSupply()
        );
        IRUY(ruy).burn(user, amountInRUY);
        IERC20(rUSD).safeTransfer(user, _yieldAmount);

        emit Withdraw(user, amountInRUY, _yieldAmount);
    }

    function setOutUSDBVault(address _outUSDBVault) external override onlyOwner {
        outUSDBVault = _outUSDBVault;
        emit SetOutUSDBVault(_outUSDBVault);
    }
}