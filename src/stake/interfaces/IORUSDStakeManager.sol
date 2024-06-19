//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IORUSDStakeManager interface
 */
interface IORUSDStakeManager {
    struct Position {
        uint104 orUSDAmount;
        uint104 osUSDAmount;
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
    function outUSDBVault() external view returns (address);

    function forceUnstakeFee() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function totalYieldPool() external view returns (uint256);

    function minLockupDays() external view returns (uint16);

    function maxLockupDays() external view returns (uint16);

    function positionsOf(uint256 positionId) external view returns (Position memory);

    function avgStakeDays() external view returns (uint256);

    function calcOSUSDAmount(uint256 amountInORUSD) external view returns (uint256);


    /** setter **/
    function setMinLockupDays(uint16 _minLockupDays) external;

    function setMaxLockupDays(uint16 _maxLockupDays) external;

    function setForceUnstakeFee(uint256 _forceUnstakeFee) external;

    function setOutUSDBVault(address _OutUSDBVault) external;


    /** function **/
    function initialize(
        address outUSDBVault_, 
        uint256 forceUnstakeFee_, 
        uint16 minLockupDays_, 
        uint16 maxLockupDays_
    ) external;

    function stake(
        uint256 amountInORUSD, 
        uint16 lockupDays, 
        address positionOwner, 
        address osUSDTo, 
        address ruyTo
    ) external returns (uint256 amountInOSUSD, uint256 amountInRUY);

    function unstake(uint256 positionId) external returns (uint256 amountInORUSD);

    function extendLockTime(uint256 positionId, uint256 extendDays) external returns (uint256 amountInRUY);

    function withdrawYield(uint256 amountInRUY) external returns (uint256 yieldAmount);

    function handleUSDBYield(uint256 nativeYield) external returns (uint256 realYield);

    function accumYieldPool(uint256 nativeYield) external;

    /** event **/
    event StakeORUSD(
        uint256 indexed positionId,
        address indexed account,
        uint256 amountInORUSD,
        uint256 amountInOSUSD,
        uint256 amountInRUY,
        uint256 deadline
    );

    event Unstake(uint256 indexed positionId, uint256 amountInORUSD, uint256 burnedOSUSD, uint256 burnedRUY);

    event WithdrawYield(address indexed account, uint256 burnedRUY, uint256 yieldAmount);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 newDeadLine, uint256 mintedRUY);

    event SetMinLockupDays(uint16 minLockupDays);

    event SetMaxLockupDays(uint16 maxLockupDays);

    event SetForceUnstakeFee(uint256 forceUnstakeFee);
    
    event SetOutUSDBVault(address outUSDBVault);
}