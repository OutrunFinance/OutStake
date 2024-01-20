//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVault {
    function deposit() external payable;

    function withdraw(uint256 _amountInSnBnb) external;

    function setBotRole(address _address) external;

    function revokeBotRole(address _address) external;
    
    function setFeeRate(uint256 _feeRate) external;

    function setRevenuePool(address _address) external;

    function setRedirectAddress(address _address) external;

    event Deposit(address _src, uint256 _amount);
   
    event Withdraw(address indexed _account, uint256 _amountInBnbX);

    event SetFeeRate(uint256 _feeRate);

    event SetRevenuePool(address indexed _address);

    event SetRedirectAddress(address indexed _address);
}