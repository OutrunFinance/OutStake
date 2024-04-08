//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IRETHStakeManager interface
 */
interface IRETHStakeManager {
    struct Position {
        uint104 RETHAmount;
        uint104 PETHAmount;
        uint40 deadline;
        bool closed;
        address owner;
    }


    /** error **/
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


    /** setter **/
    function setMinLockupDays(uint16 _minLockupDays) external;

    function setMaxLockupDays(uint16 _maxLockupDays) external;

    function setForceUnstakeFee(uint256 _forceUnstakeFee) external;

    function setOutETHVault(address _outETHVault) external;


    /** function **/
    function initialize(
        address outETHVault_,
        uint256 forceUnstakeFee_, 
        uint16 minLockupDays_, 
        uint16 maxLockupDays_
    ) external;

    function stake(
        uint256 amountInRETH, 
        uint16 lockupDays, 
        address positionOwner, 
        address pethTo, 
        address reyTo
    ) external returns (uint256 amountInPETH, uint256 amountInREY);

    function unstake(uint256 positionId) external returns (uint256 amountInRETH);

    function extendLockTime(uint256 positionId, uint256 extendDays) external returns (uint256 amountInREY);

    function withdrawYield(uint256 amountInREY) external returns (uint256 yieldAmount);

    function accumYieldPool(uint256 nativeYield) external;


    /** event **/
    event SetMinLockupDays(uint16 minLockupDays);

    event SetMaxLockupDays(uint16 maxLockupDays);

    event SetForceUnstakeFee(uint256 forceUnstakeFee);

    event SetOutETHVault(address outETHVault);

    event StakeRETH(
        uint256 indexed positionId,
        address indexed account,
        uint256 amountInRETH,
        uint256 amountInPETH,
        uint256 amountInREY,
        uint256 deadline
    );

    event Unstake(uint256 indexed positionId, uint256 amountInRETH, uint256 burnedPETH, uint256 burnedREY);

    event WithdrawYield(address indexed account, uint256 burnedREY, uint256 yieldAmount);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 newDeadLine, uint256 mintedREY);
}