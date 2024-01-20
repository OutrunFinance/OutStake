//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IStakeManager {
    function stake() external payable;

    function unStake(uint256 _amountInSnBnb) external;

    function proposeNewManager(address _address) external;

    function acceptNewManager() external;

    function setRedirectAddress(address _address) external;

    event Deposit(address _src, uint256 _amount);
   
    event Withdraw(address indexed _account, uint256 _amountInBnbX);

    event SetManager(address indexed _address);

    event ProposeManager(address indexed _address);

    event SetRedirectAddress(address indexed _address);
}