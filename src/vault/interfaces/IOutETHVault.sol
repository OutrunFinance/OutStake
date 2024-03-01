//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutETHVault {
    error ZeroInput();

    error PermissionDenied();

    error FeeRateOverflow();

    function initialize() external;

    function withdraw(address user, uint256 amount) external;

    function claimETHYield() external;

    function setFeeRate(uint256 _feeRate) external;

    function setRevenuePool(address _pool) external;

    function setRETHStakeManager(address _RETHStakeManager) external;

    event ClaimETHYield(uint256 amount);

    event SetFeeRate(uint256 _feeRate);

    event SetBot(address _bot);

    event SetRevenuePool(address _address);

    event SetRETHStakeManager(address _address);
}