//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IDepositAdapter {
    function depositETHForWeETH(address _referral) external payable returns (uint256);
}