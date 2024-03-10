//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IRETHStakeManager interface
 */
interface IRETHStakeManager {
    struct Position {
        uint96 RETHAmount;
        uint96 PETHAmount;
        uint56 deadline;
        bool closed;
        address owner;
    }

    error ZeroInput();

    error PermissionDenied();

    error PositionClosed();

    error ReachedDeadline(uint256 deadline);

    error MinStakeInsufficient(uint256 minStake);

    error InvalidLockupDays(uint256 minLockupDays, uint256 maxLockupDays);

    error InvalidExtendDays();

    error InvalidReduceDays();
    
    error ForceUnstakeFeeOverflow();

    /** view **/
    function outETHVault() external view returns (address);

    function forceUnstakeFee() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function totalYieldPool() external view returns (uint256);

    function minLockupDays() external view returns (uint16);

    function maxLockupDays() external view returns (uint16);

    function positionsOf(uint256 positionId) external view returns (Position memory);

    function getStakedRETH() external view returns (uint256);

    function avgStakeDays() external view returns (uint256);

    function calcPETHAmount(uint256 amountInRETH) external view returns (uint256);

    /** function **/
    function stake(uint256 amountInRETH, uint16 lockupDays, address positionOwner, address receiver) external returns (uint256, uint256);

    function unstake(uint256 positionId) external returns (uint256);

    function extendLockTime(uint256 positionId, uint256 extendDays) external returns (uint256);

    function withdrawYield(uint256 amountInREY) external returns (uint256);

    function updateYieldPool(uint256 nativeYield) external;

    /** setter **/
    function setMinLockupDays(uint16 _minLockupDays) external;

    function setMaxLockupDays(uint16 _maxLockupDays) external;

    function setForceUnstakeFee(uint256 _forceUnstakeFee) external;

    function setOutETHVault(address _outETHVault) external;

    event StakeRETH(
        uint256 indexed _positionId,
        address indexed _account,
        uint256 _amountInRETH,
        uint256 _deadline
    );

    event Unstake(uint256 indexed _positionId, address indexed _account, uint256 _amountInRETH);

    event WithdrawYield(address indexed user, uint256 amountInREY, uint256 yieldAmount);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 mintedREY);

    event SetMinLockupDays(uint16 _minLockupDays);

    event SetMaxLockupDays(uint16 _maxLockupDays);

    event SetForceUnstakeFee(uint256 _forceUnstakeFee);

    event SetOutETHVault(address _outETHVault);
}