//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

/**
 * @title Outrun SY Stake Manager interface
 */
interface IOutrunStakeManager {
    struct Position {
        uint256 stakedSYAmount;         // Amount of Staked SY
        uint256 principalAssetValue;    // The constant value of the principal asset
        uint256 amountInPT;             // Amount of PTs generated
        uint256 deadline;               // Position unlock time
    }

    struct LockupDuration {
        uint128 minLockupDays;      // Position min lockup days
        uint128 maxLockupDays;      // Position max lockup days
    }
    
    error ZeroInput();

    error PermissionDenied();

    error LockTimeNotExpired(uint256 deadLine);

    error MinStakeInsufficient(uint256 minStake);

    error InvalidLockupDays(uint256 minLockupDays, uint256 maxLockupDays);

    function syTotalStaking() external view returns (uint256);

    function totalPrincipalAssetValue() external view returns (uint256);

    function impliedStakingDays() external view returns (uint256);

    function calcPTAmount(uint256 nativeYieldTokenAmount, uint256 amountInYT) external view returns (uint256);

    function setLockupDuration(uint128 minLockupDays, uint128 maxLockupDays) external;

    function stake(
        uint256 stakedSYAmount,
        uint256 lockupDays, 
        address positionOwner, 
        address PTRecipient, 
        address YTRecipient
    ) external returns (uint256 amountInPT, uint256 amountInYT);

    function redeem(uint256 positionId, uint256 share) external;

    function transferYields(address receiver, uint256 syAmount) external;

    event Stake(
        uint256 indexed positionId,
        uint256 stakedSYAmount,
        uint256 principalValue,
        uint256 amountInPT,
        uint256 amountInYT,
        uint256 deadline
    );    

    event Redeem(
        uint256 indexed positionId, 
        uint256 reducedStakedSYAmount, 
        uint256 share
    );

    event SetLockupDuration(uint128 minLockupDays, uint128 maxLockupDays);
}