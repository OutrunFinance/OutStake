// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IRewardManager {
    function initialize(address POT) external;

    function userReward(address token, address user) external view returns (uint128 index, uint128 accrued);
}
