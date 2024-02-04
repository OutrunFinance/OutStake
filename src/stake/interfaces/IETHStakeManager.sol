//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IETHStakeManager {
    function stake(uint256 amount, uint256 deadLine) external;

    function unStake(uint256 amount, uint256 positionId) external;

    function getVaultETH() external returns (uint256);

    event StakeETH(address indexed _account, uint256 _amount, uint256 _deadLine);

    event Withdraw(address indexed _account, uint256 _amountInETH);
}