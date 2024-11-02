// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { Math } from "../libraries/Math.sol";
import { IPositionRewardManager } from "./interfaces/IPositionRewardManager.sol";

/**
 * @notice PositionRewardManager must not have duplicated rewardTokens
 */
abstract contract PositionRewardManager is IPositionRewardManager {
    using Math for uint256;

    uint256 internal constant INITIAL_REWARD_INDEX = 1;

    struct RewardState {
        uint128 index;
        uint128 lastBalance;
    }

    struct PositionReward {
        uint128 index;
        uint128 accrued;
        bool feesCollected;
    }

    // [token] => [positionId] => (index,accrued,feesCollected)
    mapping(address => mapping(uint256 => PositionReward)) public positionReward;

    function _updatePositionRewards(uint256 positionId, uint256 rewardShares) internal virtual {
        (address[] memory tokens, uint256[] memory indexes) = _updateRewardIndex();
        if (tokens.length == 0) return;

        for (uint256 i = 0; i < tokens.length; ++i) {
            address token = tokens[i];
            uint256 index = indexes[i];
            PositionReward storage rewardOfPosition = positionReward[tokens[i]][positionId];
            uint256 positionIndex = rewardOfPosition.index;

            if (positionIndex == 0) {
                positionIndex = INITIAL_REWARD_INDEX.Uint128();
            }

            if (positionIndex == index) continue;

            uint256 deltaIndex = index - positionIndex;
            uint256 rewardDelta = rewardShares.mulDown(deltaIndex);
            uint256 rewardAccrued = rewardOfPosition.accrued + rewardDelta;

            positionReward[token][positionId] = PositionReward(index.Uint128(), rewardAccrued.Uint128(), rewardOfPosition.feesCollected);
        }
    }

    function rewardIndexesCurrent() external virtual returns (uint256[] memory);

    function _updateRewardIndex() internal virtual returns (address[] memory tokens, uint256[] memory indexes);

    function _redeemExternalReward() internal virtual;

    function _doTransferOutRewards(
        address receiver, 
        uint256 positionId, 
        uint256 positionShare, 
        uint256 PTRedeemable
    ) internal virtual returns (uint256[] memory rewardAmounts);
}
