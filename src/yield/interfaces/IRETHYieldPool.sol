// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

 /**
  * @title RETH yield pool interface
  */
interface IRETHYieldPool {
    function withdraw(uint256 _amountInRETY) external;

    function setOutETHVault(address _outETHVault) external;

    event SetOutETHVault(address _outETHVault);

    event Withdraw(address indexed _account, uint256 _amountInRETY, uint256 _yieldAmount);
}