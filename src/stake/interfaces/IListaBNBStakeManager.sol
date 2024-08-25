//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

/**
 * @title IListaBNBStakeManager interface
 */
interface IListaBNBStakeManager {
    struct FlashLoanFeeRate {
        uint128 providerFeeRate;
        uint128 protocolFeeRate;
    }

    struct Position {
        uint256 stakedAmount;       // Amount of Staked token
        uint256 principalValue;     // The constant value of the principal, measured in native tokens
        uint256 amountInPT;         // Amount of PTs generated
        uint256 deadline;
    }

    /** error **/
    error ZeroInput();

    error MinStakeInsufficient(uint256 minStake);

    error InvalidLockupDays(uint256 minLockupDays, uint256 maxLockupDays);
    
    error FeeRateOverflow();

    error FlashLoanRepayFailed();
    

    /** view **/
    function revenuePool() external view returns (address);

    function totalStaked() external view returns (uint256);

    function yieldPool() external view returns (uint256);

    function totalPrincipalValue() external view returns (uint256);

    function protocolFeeRate() external view returns (uint256);

    function burnedYTFeeRate() external view returns (uint256);

    function forceUnstakeFeeRate() external view returns (uint256);

    function minLockupDays() external view returns (uint128);

    function maxLockupDays() external view returns (uint128);

    function flashLoanFeeRate() external view returns (FlashLoanFeeRate memory);

    function avgStakeDays() external view returns (uint256);

    function calcPTAmount(uint256 amountInORETH, uint256 amountInREY) external view returns (uint256);


    /** setter **/
    function setRevenuePool(address revenuePool_) external;

    function setProtocolFeeRate(uint256 protocolFeeRate_) external;

    function setBurnedYTFeeRate(uint256 _burnedYTFee) external;

    function setForceUnstakeFeeRate(uint256 _forceUnstakeFee) external;

    function setMinLockupDays(uint128 _minLockupDays) external;

    function setMaxLockupDays(uint128 _maxLockupDays) external;

    function setFlashLoanFeeRate(uint128 _providerFeeRate, uint128 _protocolFeeRate) external;    


    /** function **/
    function initialize(
        address revenuePool_,
        uint256 protocolFeeRate_, 
        uint256 burnedYTFeeRate_,
        uint256 forceUnstakeFeeRate_, 
        uint128 minLockupDays_, 
        uint128 maxLockupDays_,
        uint128 flashLoanProviderFeeRate_, 
        uint128 flashLoanProtocolFeeRate_
    ) external;

    function stake(
        uint256 slisBNBAmount,
        uint256 lockupDays, 
        address positionOwner, 
        address pslisBNBTo, 
        address yslisBNBTo
    ) external returns (uint256 amountInPT, uint256 amountInYT);

    function unstake(uint256 positionId, uint256 share) external;

    function accumSlisBNBYield() external;

    function withdrawYield(uint256 burnedYTAmount) external returns (uint256 yieldAmount);

    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external;


    /** event **/
    event SetRevenuePool(address revenuePool);

    event SetProtocolFeeRate(uint256 protocolFeeRate);

    event SetBurnedYTFeeRate(uint256 burnedYTFeeRate);

    event SetForceUnstakeFeeRate(uint256 forceUnstakeFeeRate);

    event SetMinLockupDays(uint128 minLockupDays);

    event SetMaxLockupDays(uint128 maxLockupDays);

    event SetFlashLoanFeeRate(uint128 providerFeeRate, uint128 protocolFeeRate);

    event StakeSlisBNB(
        uint256 indexed positionId,
        uint256 slisBNBAmount,
        uint256 constPrincipalValue,
        uint256 amountInPT,
        uint256 amountInYT,
        uint256 deadline
    );    

    event Unstake(uint256 indexed positionId, uint256 reducedSlisBNBAmount, uint256 share, uint256 burnedYTAmount);

    event AccumSlisBNBYield(uint256 increasedYield);

    event WithdrawYield(address indexed account, uint256 burnedYTAmount, uint256 yieldAmount);

    event FlashLoan(address indexed receiver, uint256 amount, uint256 providerFeeAmount, uint256 protocolFeeAmount);
}