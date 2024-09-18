// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "./interfaces/ActionType.sol";
import "../core/libraries/Math.sol";
import "../core/libraries/TokenHelper.sol";
import "../core/StandardizedYield/IStandardizedYield.sol";
import "../core/YieldContracts/interfaces/IYieldToken.sol";

abstract contract OutStakeRouter is TokenHelper {
    using Math for uint256;

    // ----------------- MINT REDEEM SY -----------------
    function _mintSYFromToken(
        address receiver,
        address SY,
        uint256 minSyOut,
        TokenInput calldata input
    ) internal returns (uint256 amountInSYOut) {
        uint256 amountInDeposited;
        TokenType tokenType = input.tokenType;
        if (tokenType == TokenType.NONE) {
            _transferIn(input.tokenIn, msg.sender, input.amount);
            amountInDeposited = input.amount;
        } else {
            _transferIn(input.tokenIn, msg.sender, input.amount);
            _wrap_unwrap_ETH(input.tokenIn, input.depositedToken, input.amount);
            amountInDeposited = input.amount;
        }

        amountInSYOut = _mintSY(receiver, SY, amountInDeposited, minSyOut, input);
    }

    function _mintSY(
        address receiver,
        address SY,
        uint256 amountInDeposited,
        uint256 minSyOut,
        TokenInput calldata input
    ) private returns (uint256 amountInSYOut) {
        uint256 amountInNative = input.depositedToken == NATIVE ? amountInDeposited : 0;
        _safeApproveInf(input.depositedToken, SY);
        amountInSYOut = IStandardizedYield(SY).deposit{value: amountInNative}(
            receiver,
            input.depositedToken,
            amountInDeposited,
            minSyOut
        );
    }

    function _redeemSyToToken(
        address receiver,
        address SY,
        uint256 amountInSY,
        TokenOutput calldata output,
        bool doPull
    ) internal returns (uint256 amountInTokenOut) {
        TokenType tokenType = output.tokenType;

        if (tokenType == TokenType.NONE) {
            amountInTokenOut = _redeemSy(receiver, SY, amountInSY, output, doPull);
        } else {
            amountInTokenOut = _redeemSy(address(this), SY, amountInSY, output, doPull); // ETH:WETH is 1:1
            _wrap_unwrap_ETH(output.redeemedToken, output.tokenOut, amountInTokenOut);
            _transferOut(output.tokenOut, receiver, amountInTokenOut);
        }

        if (amountInTokenOut < output.minTokenOut) revert("Slippage: INSUFFICIENT_TOKEN_OUT");
    }

    function _redeemSy(
        address receiver,
        address SY,
        uint256 amountInSY,
        TokenOutput calldata output,
        bool doPull
    ) private returns (uint256 amountInRedeemed) {
        if (doPull) {
            _transferFrom(IERC20(SY), msg.sender, SY, amountInSY);
        }

        amountInRedeemed = IStandardizedYield(SY).redeem(receiver, amountInSY, output.redeemedToken, 0, true);
    }
}
