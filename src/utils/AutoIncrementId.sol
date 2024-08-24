// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

abstract contract AutoIncrementId {
    uint256 public idCounter = 0;

    function _nextId() internal returns (uint256) {
        unchecked {
            ++idCounter;
        }
        return idCounter;
    }
}
