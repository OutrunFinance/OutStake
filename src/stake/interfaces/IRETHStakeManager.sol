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

    function stake(uint256 amountInRETH, uint256 lockupDays) external;

    function unStake(uint256 amountInPETH, uint256 positionId) external;

    function getStakedRETH() external returns (uint256);

    function setRETHYieldPool(address pool) external;

    function setMinLockupDays(uint256 minLockupDays) external;

    function setMaxLockupDays(uint256 maxLockupDays) external;

    event StakeRETH(
        address indexed _account,
        uint256 _amountInRETH,
        uint256 _deadLine,
        uint256 _positionId
    );

    event Withdraw(address indexed _account, uint256 _amountInRETH);

    event SetRETHYieldPool(address _pool);

    event SetMinLockupDays(uint256 _minLockupDays);

    event SetMaxLockupDays(uint256 _maxLockupDays);
}