//SPDX-License-Identifier: GPL-3.0rETH
pragma solidity ^0.8.19;

/**
 * @title IRUSDStakeManager interface
 */
interface IRUSDStakeManager {
    struct Position {
        uint256 positionId;
        uint256 RUSDAmount;
        uint256 PUSDAmount;
        address owner;
        uint256 deadLine;
        bool closed;
    }

    function positionsOf(uint256 positionId) external returns (Position memory);

    function stake(uint256 amount, uint256 deadLine) external;

    function unStake(uint256 amount, uint256 positionId) external;

    function getStakedRUSD() external returns (uint256);

    function setUSDBYieldPool(address pool) external;

    function setMinIntervalTime(uint256 interval) external;

    function setMaxIntervalTime(uint256 interval) external;

    event StakeUSDB(
        address indexed _account,
        uint256 _amount,
        uint256 _deadLine,
        uint256 _positionId
    );

    event Withdraw(address indexed _account, uint256 _amountInRUSD);

    event SetUSDBYieldPool(address _pool);

    event SetMinIntervalTime(uint256 _minIntervalTime);

    event SetMaxIntervalTime(uint256 _maxIntervalTime);
}