// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

interface IChainlinkPriceFeed is AggregatorV3Interface {
    /**
     * @notice Old Chainlink function for getting the number of latest round
     * @return latestRound The number of the latest update round
     */
    function latestRound() external view returns (uint80);

    /**
     * @notice Old Chainlink function for getting the latest successfully reported value
     * @return latestAnswer The latest successfully reported value
     */
    function latestAnswer() external view returns (int256);
}
