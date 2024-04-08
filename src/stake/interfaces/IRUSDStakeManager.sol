//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IRUSDStakeManager interface
 */
interface IRUSDStakeManager {
    struct Position {
        uint104 RUSDAmount;
        uint104 PUSDAmount;
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

    function getStakedRUSD() external view returns (uint256);

    function avgStakeDays() external view returns (uint256);

    function calcPUSDAmount(uint256 amountInRUSD) external view returns (uint256);


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
        uint256 amountInRUSD, 
        uint16 lockupDays, 
        address positionOwner, 
        address pusdTo, 
        address ruyTo
    ) external returns (uint256 amountInPUSD, uint256 amountInRUY);

    function unstake(uint256 positionId) external returns (uint256 amountInRUSD) ;

    function extendLockTime(uint256 positionId, uint256 extendDays) external returns (uint256 amountInRUY) ;

    function withdrawYield(uint256 amountInRUY) external returns (uint256 yieldAmount) ;

    function accumYieldPool(uint256 nativeYield) external;

    /** event **/
    event StakeRUSD(
        uint256 indexed positionId,
        address indexed account,
        uint256 amountInRUSD,
        uint256 amountInPUSD,
        uint256 amountInRUY,
        uint256 deadline
    );

    event Unstake(uint256 indexed positionId, uint256 amountInRUSD, uint256 burnedPUSD, uint256 burnedRUY);

    event WithdrawYield(address indexed account, uint256 burnedRUY, uint256 yieldAmount);

    event ExtendLockTime(uint256 indexed positionId, uint256 extendDays, uint256 newDeadLine, uint256 mintedRUY);

    event SetMinLockupDays(uint16 minLockupDays);

    event SetMaxLockupDays(uint16 maxLockupDays);

    event SetForceUnstakeFee(uint256 forceUnstakeFee);
    
    event SetOutUSDBVault(address outUSDBVault);
}