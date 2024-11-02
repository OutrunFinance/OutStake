// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { IExchangeRateOracle } from "./interfaces/IExchangeRateOracle.sol";
import { IChainlinkPriceFeed } from "./interfaces/IChainlinkPriceFeed.sol";

contract OutrunChainlinkRateOracleAdapter is IExchangeRateOracle {
    address public immutable oracle;
    uint8 public immutable decimals;
    uint8 public immutable rawDecimals;

    constructor(address _oracle, uint8 _decimals) {
        oracle = _oracle;
        decimals = _decimals;
        rawDecimals = IChainlinkPriceFeed(_oracle).decimals();
    }

    function getExchangeRate() external view returns (uint256) {
        int256 answer = IChainlinkPriceFeed(oracle).latestAnswer();
        require(answer > 0, "Error answer");
        return (uint256(answer) * 10 ** decimals) / 10 ** rawDecimals;
    }
}
