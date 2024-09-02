//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IStakeLisUSDListaDistributor {
    function claimableReward(address account) external view returns (uint256);

    function claimReward() external returns (uint256);
}