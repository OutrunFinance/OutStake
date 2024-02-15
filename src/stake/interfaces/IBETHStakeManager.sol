//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

/**
 * @title IBETHStakeManager interface
 */
interface IBETHStakeManager {
    struct Position {
        uint256 positionId;
        uint256 BETHAmount;
        uint256 PETHAmount;
        address owner;
        uint256 deadLine;
        bool closed;
    }

    function positionsOf(uint256 positionId) external returns (Position memory);

    function stake(uint256 amount, uint256 deadLine) external;

    function unStake(uint256 amount, uint256 positionId) external;

    function getStakedBETH() external returns (uint256);

    function setBETHYieldPool(address pool) external;

    function setMinIntervalTime(uint256 interval) external;

    function setMaxIntervalTime(uint256 interval) external;

    event StakeBETH(
        address indexed _account,
        uint256 _amount,
        uint256 _deadLine,
        uint256 _positionId
    );

    event Withdraw(address indexed _account, uint256 _amountInBETH);

    event SetBETHYieldPool(address _pool);

    event SetMinIntervalTime(uint256 _minIntervalTime);

    event SetMaxIntervalTime(uint256 _maxIntervalTime);
}