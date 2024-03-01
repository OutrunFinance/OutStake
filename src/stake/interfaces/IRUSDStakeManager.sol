//SPDX-License-Identifier: GPL-3.0
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

    function getStakedRUSD() external returns (uint256);

    function stake(uint256 amountInRUSD, uint256 lockupDays) external;

    function unStake(uint256 positionId) external;

    function withdraw(uint256 amountInRUY) external;

    function extendLockTime(uint256 positionId, uint256 extendDays) external;
    
    function reduceLockTime(uint256 positionId, uint256 reduceDays) external;

    function updateYieldAmount(uint256 yieldAmount) external;

    function setMinLockupDays(uint256 minLockupDays) external;

    function setMaxLockupDays(uint256 maxLockupDays) external;

    function setReduceLockFee(uint256 reduceLockFee) external;

    function setOutUSDBVault(address _OutUSDBVault) external;

    event StakeRUSD(
        uint256 indexed _positionId,
        address indexed _account,
        uint256 _amountInRUSD,
        uint256 _deadLine
    );

    event UnStake(uint256 indexed _positionId, address indexed _account, uint256 _amountInRUSD);

    event Withdraw(address indexed user, uint256 amountInRUY, uint256 yieldAmount);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 mintedRUY);

    event ReduceLockTime(uint256 indexed positionId, uint256 reduceDays, uint256 burnedRUY);

    event SetMinLockupDays(uint256 _minLockupDays);

    event SetMaxLockupDays(uint256 _maxLockupDays);

    event SetReduceLockFee(uint256 _reduceLockFee);
    
    event SetOutUSDBVault(address _outUSDBVault);
}