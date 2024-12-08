// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import {BlastModeEnum} from "./BlastModeEnum.sol";

interface IBlastGovernorable is BlastModeEnum  {
    function configure(YieldMode yieldMode, GasMode gasMode) external;

    function readGasBalance() external view returns (uint256);

    function claimMaxGas(address recipient) external returns (uint256 gasAmount);

    function transferGasManager(address newBlastGovernor) external;
}