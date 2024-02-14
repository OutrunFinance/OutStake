// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

 /**
  * @title ETH yield pool interface
  */
interface IETHYieldPool {
    function withdraw(uint256 _amountInBETY) external;

    event Withdraw(address indexed _account, uint256 _amountInBETY, uint256 _yieldAmount);
}