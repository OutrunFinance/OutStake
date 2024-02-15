// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

 /**
  * @title BUSD yield pool interface
  */
interface IBUSDYieldPool {
    function withdraw(uint256 _amountInBUTY) external;

    event Withdraw(address indexed _account, uint256 _amountInBUTY, uint256 _yieldAmount);
}