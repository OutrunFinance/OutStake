//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IOutFlashCallee {
     function onFlashLoan(address sender, uint256 amount, bytes calldata data) external;
}