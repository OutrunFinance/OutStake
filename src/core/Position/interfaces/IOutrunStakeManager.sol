//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

/**
 * @title Outrun SY Stake Manager interface
 */
interface IOutrunStakeManager {
    struct Position {
        uint256 SYRedeemable;           // Amount of SY redeemable
        uint256 PTRedeemable;           // Amount of PT redeemable
        uint256 principalRedeemable;    // The principal value redeemable
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

    function totalPrincipalValue() external view returns (uint256);

    function impliedStakingDays() external view returns (uint256);

    function calcPTAmount(uint256 principalValue, uint256 amountInYT) external view returns (uint256);

    function setLockupDuration(uint128 minLockupDays, uint128 maxLockupDays) external;

    function stake(
        uint256 stakedSYAmount,
        uint256 lockupDays, 
        address positionOwner, 
        address PTRecipient, 
        address YTRecipient
    ) external returns (uint256 PTGenerated, uint256 YTGenerated);

    function redeem(uint256 positionId, uint256 positionShare) external;

    function transferYields(address receiver, uint256 syAmount) external;


    event Stake(
        uint256 indexed positionId,
        uint256 stakedSYAmount,
        uint256 principalValue,
        uint256 PTGenerated,
        uint256 YTGenerated,
        uint256 deadline
    );    

    event Redeem(
        uint256 indexed positionId, 
        address indexed account,
        uint256 reducedStakedSYAmount, 
        uint256 positionShare
    );

    event SetLockupDuration(uint128 minLockupDays, uint128 maxLockupDays);
}