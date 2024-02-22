//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IRETHStakeManager interface
 */
interface IRETHStakeManager {
    struct Position {
        uint256 RETHAmount;
        uint256 PETHAmount;
        address owner;
        uint256 deadLine;
        bool closed;
    }

    function positionsOf(uint256 positionId) external returns (Position memory);

    function stake(uint256 amountInRETH, uint256 deadLine) external;

    function unStake(uint256 amountInPETH, uint256 positionId) external;

    function getStakedRETH() external returns (uint256);

    function setRETHYieldPool(address pool) external;

    function setMinIntervalTime(uint256 interval) external;

    function setMaxIntervalTime(uint256 interval) external;

    event StakeRETH(
        address indexed _account,
        uint256 _amountInRETH,
        uint256 _deadLine,
        uint256 _positionId
    );

    event Withdraw(address indexed _account, uint256 _amountInRETH);

    event SetRETHYieldPool(address _pool);

    event SetMinIntervalTime(uint256 _minIntervalTime);

    event SetMaxIntervalTime(uint256 _maxIntervalTime);
}