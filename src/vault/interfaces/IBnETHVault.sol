//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IBnETHVault {
    function withdraw(address account, uint256 amount) external;

    function getVaultETH() external returns (uint256);

    function compound() external;

    function setBotRole(address _address) external;

    function revokeBotRole(address _address) external;

    function setFeeRate(uint256 _feeRate) external;

    function setRevenuePool(address _pool) external;

    event SetFeeRate(uint256 _feeRate);

    event SetRevenuePool(address _address);

    event Compounded(uint256 amount);
}