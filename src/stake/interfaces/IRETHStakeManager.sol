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

    function unStake(uint256 positionId) external;

    function extendLockTime(uint256 positionId, uint256 extendDays) external;
    
    function reduceLockTime(uint256 positionId, uint256 reduceDays) external;

    function getStakedRETH() external returns (uint256);

    function setRETHYieldPool(address pool) external;

    function setMinLockupDays(uint256 minLockupDays) external;

    function setMaxLockupDays(uint256 maxLockupDays) external;

    function setReduceLockFee(uint256 reduceLockFee) external;

    event StakeRETH(
        uint256 indexed _positionId,
        address indexed _account,
        uint256 _amountInRETH,
        uint256 _deadLine
    );

    event UnStake(uint256 indexed _positionId, address indexed _account, uint256 _amountInRETH);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 mintedREY);

    event ReduceLockTime(uint256 indexed positionId, uint256 reduceDays, uint256 burnedREY);

    event SetRETHYieldPool(address _pool);

    event SetMinLockupDays(uint256 _minLockupDays);

    event SetMaxLockupDays(uint256 _maxLockupDays);

    event SetReduceLockFee(uint256 _reduceLockFee);
}