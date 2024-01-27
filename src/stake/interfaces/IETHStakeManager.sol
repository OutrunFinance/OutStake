//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IETHStakeManager {
    function stake(uint256 deadLine) external payable ;

    function unStake(uint256 amount, uint256 positionId) external;

    function settlementYield(address account, uint256 positionId) external;

    function getVaultETH() external returns (uint256);

    function convertToBETH(uint256 amountInETH) external returns (uint256);

    function convertToETH(uint256 amountInBETH) external returns (uint256);

    function setManager(address _manager) external;

    event StakeETH(address indexed _account, uint256 _amount, uint256 _deadLine);

    event Withdraw(address indexed _account, uint256 _amountInETH);

    event SetManager(address indexed _address);
}
