// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {BlastModeEnum} from "./BlastModeEnum.sol";

interface IERC20Rebasing is BlastModeEnum {
    function configure(YieldMode) external returns (uint256);

    function claim(address recipient,uint256 amount) external returns (uint256);

    function getClaimableAmount(address account) external view returns (uint256);
}
