// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.24;

library Math {
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            return a / b;
        }

        return a == 0 ? 0 : (a - 1) / b + 1;
    }
}