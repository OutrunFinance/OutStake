// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

 /**
  * @title RUSD yield pool interface
  */
interface IRUSDYieldPool {
    function withdraw(uint256 _amountInRUTY) external;

    function setOutUSDBVault(address _outUSDBVault) external;
    
    event SetOutUSDBVault(address _outUSDBVault);

    event Withdraw(address indexed _account, uint256 _amountInRUTY, uint256 _yieldAmount);
}