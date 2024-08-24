//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/**
 * @title IORUSDStakeManager interface
 */
interface IORUSDStakeManager {
    /** error **/
    error ZeroInput();

    error PermissionDenied();

    error PositionClosed();

    error ReachedDeadline(uint256 deadline);

    error MinStakeInsufficient(uint256 minStake);

    error InvalidLockupDays(uint256 minLockupDays, uint256 maxLockupDays);

    error InvalidExtendDays();

    error InvalidReduceDays();
    
    error FeeOverflow();
    

    /** view **/
    function forceUnstakeFee() external view returns (uint256);

    function burnedYTFee() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function totalYieldPool() external view returns (uint256);

    function minLockupDays() external view returns (uint128);

    function maxLockupDays() external view returns (uint128);

    function avgStakeDays() external view returns (uint256);

    function calcOSUSDAmount(uint256 amountInORUSD, uint256 amountInRUY) external view returns (uint256);


    /** setter **/
    function setMinLockupDays(uint128 _minLockupDays) external;

    function setMaxLockupDays(uint128 _maxLockupDays) external;

    function setForceUnstakeFee(uint256 _forceUnstakeFee) external;

    function setBurnedYTFee(uint256 _burnedYTFee) external;


    /** function **/
    function initialize(
        uint256 forceUnstakeFee_, 
        uint256 burnedYTFee_, 
        uint128 minLockupDays_, 
        uint128 maxLockupDays_
    ) external;

    function stake(
        uint128 amountInORUSD, 
        uint256 lockupDays, 
        address positionOwner, 
        address osUSDTo, 
        address ruyTo
    ) external returns (uint256 amountInOSUSD, uint256 amountInRUY);

    function unstake(uint256 positionId, uint256 share) external;

    function withdrawYield(uint256 amountInRUY) external returns (uint256 yieldAmount);

    function handleUSDBYield(
        uint256 protocolFee, 
        address revenuePool
    ) external returns (uint256);

    function accumYieldPool(uint256 nativeYield) external;

    /** event **/
    event StakeORUSD(
        uint256 indexed positionId,
        uint256 amountInORUSD,
        uint256 amountInOSUSD,
        uint256 amountInRUY,
        uint256 deadline
    );

    event Unstake(uint256 indexed positionId, uint256 amountInORUSD, uint256 burnedOSUSD, uint256 burnedRUY);

    event WithdrawYield(address indexed account, uint256 burnedRUY, uint256 yieldAmount);

    event SetMinLockupDays(uint128 minLockupDays);

    event SetMaxLockupDays(uint128 maxLockupDays);

    event SetForceUnstakeFee(uint256 forceUnstakeFee);

    event SetBurnedYTFee(uint256 burnedYTFee);
}