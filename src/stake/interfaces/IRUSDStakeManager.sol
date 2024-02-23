//SPDX-License-Identifier: GPL-3.0rETH
pragma solidity ^0.8.24;

/**
 * @title IRUSDStakeManager interface
 */
interface IRUSDStakeManager {
    struct Position {
        uint256 RUSDAmount;
        uint256 PUSDAmount;
        address owner;
        uint256 deadLine;
        bool closed;
    }

    function positionsOf(uint256 positionId) external returns (Position memory);

    function stake(uint256 amountInRUSD, uint256 lockupDays) external;

    function unStake(uint256 amountInPUSD, uint256 positionId) external;

    function getStakedRUSD() external returns (uint256);

    function setRUSDYieldPool(address pool) external;

    function setMinLockupDays(uint256 minLockupDays) external;

    function setMaxLockupDays(uint256 maxLockupDays) external;

    event StakeRUSD(
        address indexed _account,
        uint256 _amountInRUSD,
        uint256 _deadLine,
        uint256 _positionId
    );

    event Withdraw(address indexed _account, uint256 _amountInRUSD);

    event SetRUSDYieldPool(address _pool);

    event SetMinLockupDays(uint256 _minLockupDays);

    event SetMaxLockupDays(uint256 _maxLockupDays);
}