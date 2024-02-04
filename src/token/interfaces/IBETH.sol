// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

 /**
  * @title BETH interface
  */
interface IBETH {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function setBnETHVault(address _address) external;

    event Deposit(address indexed _account, uint256 _amount);

    event Withdraw(address indexed _account, uint256 _amount);
    
    event SetBnETHVault(address  _address);
}