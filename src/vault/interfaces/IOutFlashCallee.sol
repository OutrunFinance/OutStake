//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutFlashCallee {
     function execute(address sender, uint256 amount, bytes calldata data) external;
}