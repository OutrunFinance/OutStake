// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IExchangeRateOracle {
    function getExchangeRate() external view returns (uint256);
}
