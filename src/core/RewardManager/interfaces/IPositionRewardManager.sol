// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IPositionRewardManager {
    function positionReward(address token, uint256 positionId) external view returns (uint128 index, uint128 accrued, bool feesCollected);

    event RedeemRewards(
        uint256 indexed positionId, 
        address indexed msgSender, 
        uint256[] amountRewardsOut, 
        uint256 positionShare
    );

    event CollectRewardFee(address indexed rewardToken, uint256 amountRewardFee);
}
