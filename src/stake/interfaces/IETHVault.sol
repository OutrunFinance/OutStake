//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IETHVault {
    function deposit() external payable;

    function withdraw(uint256 _amountInBETH) external;

    function compoundRewards() external;

    function setBotRole(address _address) external;

    function revokeBotRole(address _address) external;
    
    function setFeeRate(uint256 _feeRate) external;

    function setRevenuePool(address _address) external;

    event Deposit(address _src, uint256 _amount);
   
    event Withdraw(address indexed _account, uint256 _amountInBnbX);

    event RewardsCompounded(uint256 _amount);

    event SetFeeRate(uint256 _feeRate);

    event SetRevenuePool(address indexed _address);
}