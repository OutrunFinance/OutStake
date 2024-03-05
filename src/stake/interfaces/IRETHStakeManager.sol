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
        uint256 deadline;
        bool closed;
    }

    error ZeroInput();

    error PermissionDenied();

    error PositionClosed();

    error ReachedDeadline(uint256 deadline);

    error NotReachedDeadline(uint256 deadline);

    error MinStakeInsufficient(uint256 minStake);

    error InvalidLockupDays(uint256 minLockupDays, uint256 maxLockupDays);

    error InvalidExtendDays();

    error InvalidReduceDays();
    
    error ForceUnstakeFeeOverflow();

    function totalYieldPool() view external returns (uint256);

    function positionsOf(uint256 positionId) view external returns (Position memory);

    function getStakedRETH() view external returns (uint256);

    function avgStakeDays() view external returns (uint256);

    function stake(uint256 amountInRETH, uint256 lockupDays) external;

    function unstake(uint256 positionId) external;

    function forceUnstake(uint256 positionId) external;

    function extendLockTime(uint256 positionId, uint256 extendDays) external;

    function withdrawYield(uint256 amountInREY) external;

    function updateYieldAmount(uint256 yieldAmount) external;

    function setMinLockupDays(uint256 _minLockupDays) external;

    function setMaxLockupDays(uint256 _maxLockupDays) external;

    function setForceUnstakeFee(uint256 _forceUnstakeFee) external;

    function setOutETHVault(address _outETHVault) external;

    event StakeRETH(
        uint256 indexed _positionId,
        address indexed _account,
        uint256 _amountInRETH,
        uint256 _deadline
    );

    event Unstake(uint256 indexed _positionId, address indexed _account, uint256 _amountInRETH);

    event ForceUnstake(uint256 indexed positionId, uint256 burnedREY);

    event WithdrawYield(address indexed user, uint256 amountInREY, uint256 yieldAmount);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 mintedREY);

    event SetMinLockupDays(uint256 _minLockupDays);

    event SetMaxLockupDays(uint256 _maxLockupDays);

    event SetForceUnstakeFee(uint256 _forceUnstakeFee);

    event SetOutETHVault(address _outETHVault);
}