//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IRUSDStakeManager interface
 */
interface IRUSDStakeManager {
    struct Position {
        uint96 RUSDAmount;
        uint96 PUSDAmount;
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
    function outUSDBVault() external view returns (address);

    function forceUnstakeFee() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function totalYieldPool() external view returns (uint256);

    function minLockupDays() external view returns (uint16);

    function maxLockupDays() external view returns (uint16);

    function positionsOf(uint256 positionId) external view returns (Position memory);

    function getStakedRUSD() external view returns (uint256);

    function avgStakeDays() external view returns (uint256);

    function calcPUSDAmount(uint256 amountInRUSD) external view returns (uint256);

    /** function **/
    function initialize(
        address outUSDBVault_, 
        uint256 forceUnstakeFee_, 
        uint16 minLockupDays_, 
        uint16 maxLockupDays_
    ) external;

    function stake(uint256 amountInRETH, uint16 lockupDays, address positionOwner, address receiver) external returns (uint256, uint256);

    function unstake(uint256 positionId) external returns (uint256) ;

    function extendLockTime(uint256 positionId, uint256 extendDays) external returns (uint256) ;

    function withdrawYield(uint256 amountInRUY) external returns (uint256) ;

    function updateYieldPool(uint256 nativeYield) external;

    /** setter **/
    function setMinLockupDays(uint16 _minLockupDays) external;

    function setMaxLockupDays(uint16 _maxLockupDays) external;

    function setForceUnstakeFee(uint256 _forceUnstakeFee) external;

    function setOutUSDBVault(address _OutUSDBVault) external;

    event StakeRUSD(
        uint256 indexed _positionId,
        address indexed _account,
        uint256 _amountInRUSD,
        uint256 _deadline
    );

    event Unstake(uint256 indexed _positionId, address indexed _account, uint256 _amountInRUSD);

    event WithdrawYield(address indexed user, uint256 amountInRUY, uint256 yieldAmount);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 mintedRUY);

    event SetMinLockupDays(uint16 _minLockupDays);

    event SetMaxLockupDays(uint16 _maxLockupDays);

    event SetForceUnstakeFee(uint256 _forceUnstakeFee);
    
    event SetOutUSDBVault(address _outUSDBVault);
}