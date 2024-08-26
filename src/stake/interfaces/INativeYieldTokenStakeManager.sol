//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

/**
 * @title Native Yield Token StakeManager interface
 */
interface INativeYieldTokenStakeManager {
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

    function avgStakeDays() external view returns (uint256);

    function calcPTAmount(uint256 nativeYieldTokenAmount, uint256 amountInYT) external view returns (uint256);


    /** setter **/
    function setRevenuePool(address revenuePool) external;

    function setProtocolFeeRate(uint256 protocolFeeRate) external;

    function setBurnedYTFeeRate(uint256 burnedYTFeeRate) external;

    function setForceUnstakeFeeRate(uint256 forceUnstakeFeeRate) external;

    function setMinLockupDays(uint128 minLockupDays) external;

    function setMaxLockupDays(uint128 maxLockupDays) external;

    function setFlashLoanFeeRate(uint128 providerFeeRate, uint128 protocolFeeRate) external;    


    /** function **/
    function initialize(
        address revenuePool,
        uint256 protocolFeeRate, 
        uint256 burnedYTFeeRate,
        uint256 forceUnstakeFeeRate, 
        uint128 minLockupDays, 
        uint128 maxLockupDays,
        uint128 flashLoanProviderFeeRate, 
        uint128 flashLoanProtocolFeeRate
    ) external;

    function stake(
        uint256 stakedAmount,
        uint256 lockupDays, 
        address positionOwner, 
        address ptRecipient, 
        address ytRecipient
    ) external returns (uint256 amountInPT, uint256 amountInYT);

    function unstake(uint256 positionId, uint256 share) external;

    function accumYield() external;

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

    event Stake(
        uint256 indexed positionId,
        uint256 stakedAmount,
        uint256 constPrincipalValue,
        uint256 amountInPT,
        uint256 amountInYT,
        uint256 deadline
    );    

    event Unstake(
        uint256 indexed positionId, 
        uint256 reducedAmount, 
        uint256 share, 
        uint256 burnedYTAmount, 
        uint256 forceUnstakeFee
    );

    event AccumYield(uint256 increasedYield);

    event WithdrawYield(address indexed account, uint256 burnedYTAmount, uint256 yieldAmount);

    event FlashLoan(address indexed receiver, uint256 amount, uint256 providerFeeAmount, uint256 protocolFeeAmount);
}