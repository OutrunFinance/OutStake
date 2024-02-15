// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

 /**
  * @title RUSD yield pool interface
  */
interface IRUSDYieldPool {
    function withdraw(uint256 _amountInRUTY) external;

    event Withdraw(address indexed _account, uint256 _amountInRUTY, uint256 _yieldAmount);
}