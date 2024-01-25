//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IETHStakeManager {
    function stake(uint256 _lockTime) external payable;

    function unStake(uint256 _amountInSnBnb) external;

    function acceptNewManager() external;

    function setRedirectAddress(address _address) external;

    event StakeETH(address _src, uint256 _amount, uint256 _deadLine);
   
    event Withdraw(address indexed _account, uint256 _amountInBnbX);

    event SetManager(address indexed _address);

    event ProposeManager(address indexed _address);

    event SetRedirectAddress(address indexed _address);
}