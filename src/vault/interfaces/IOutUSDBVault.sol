//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutUSDBVault {
    function withdraw(address user, uint256 amount) external;

    function claimUSDBYield() external;

    function setFeeRate(uint256 _feeRate) external;

    function setRevenuePool(address _pool) external;

    function setYieldPool(address _pool) external;

    event ClaimUSDBYield(uint256 amount);

    event SetFeeRate(uint256 _feeRate);

    event SetBot(address _bot);

    event SetRevenuePool(address _address);

    event SetYieldPool(address _address);
}