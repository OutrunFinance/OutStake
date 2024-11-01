// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "./interfaces/IOutStakeRouter.sol";
import "../core/libraries/TokenHelper.sol";
import "../core/StandardizedYield/IStandardizedYield.sol";
import "../core/Position/interfaces/IOutrunStakeManager.sol";

contract OutStakeRouter is IOutStakeRouter, TokenHelper {
    /** MINT/REDEEM SY **/
    function mintSYFromToken(
        address SY,
        address tokenIn,
        address receiver,
        uint256 amountInput,
        uint256 minSyOut
    ) external payable returns (uint256 amountInSYOut) {
        _transferIn(tokenIn, msg.sender, amountInput);

        amountInSYOut = _mintSY(SY, tokenIn, receiver, amountInput, minSyOut);
    }

    function redeemSyToToken(
        address SY,
        address receiver,
        address tokenOut,
        uint256 amountInSY,
        uint256 minTokenOut
    ) external returns (uint256 amountInTokenOut) {
        amountInTokenOut = _redeemSy(SY, receiver, tokenOut, amountInSY, minTokenOut);
    }

    function _mintSY(
        address SY,
        address tokenIn,
        address receiver,
        uint256 amountInput,
        uint256 minSyOut
    ) internal returns (uint256 amountInSYOut) {
        uint256 amountInNative = tokenIn == NATIVE ? amountInput : 0;
        _safeApproveInf(tokenIn, SY);
        amountInSYOut = IStandardizedYield(SY).deposit{value: amountInNative}(
            receiver,
            tokenIn,
            amountInput,
            minSyOut
        );
    }

    function _redeemSy(
        address SY,
        address receiver,
        address tokenOut,
        uint256 amountInSY,
        uint256 minTokenOut
    ) internal returns (uint256 amountInRedeemed) {
        _transferFrom(IERC20(SY), msg.sender, SY, amountInSY);

        amountInRedeemed = IStandardizedYield(SY).redeem(receiver, amountInSY, tokenOut, minTokenOut, true);
    }

    /** MINT Yield Tokens(PT, YT, POT) **/
    function mintYieldTokensFromToken(
        address SY,
        address POT,
        address tokenIn,
        uint256 tokenAmount,
        StakeParam calldata stakeParam
    ) external payable returns (uint256 PTGenerated, uint256 YTGenerated) {
        _transferIn(tokenIn, msg.sender, tokenAmount);
        uint256 amountInSY = _mintSY(SY, tokenIn, address(this), tokenAmount, 0);

        _safeApproveInf(SY, POT);
        (PTGenerated, YTGenerated) = _mintYieldTokensFromSY(
            POT,
            amountInSY, 
            stakeParam.lockupDays,
            stakeParam.minPTGenerated,
            stakeParam.PTRecipient, 
            stakeParam.YTRecipient, 
            stakeParam.positionOwner
        );
    }

    function mintYieldTokensFromSY(
        address SY,
        address POT,
        uint256 amountInSY,
        StakeParam calldata stakeParam
    ) external returns (uint256 PTGenerated, uint256 YTGenerated) {
        _transferFrom(IERC20(SY), msg.sender, address(this), amountInSY);

        _safeApproveInf(SY, POT);
        (PTGenerated, YTGenerated) = _mintYieldTokensFromSY(
            POT,
            amountInSY, 
            stakeParam.lockupDays,
            stakeParam.minPTGenerated,
            stakeParam.PTRecipient, 
            stakeParam.YTRecipient, 
            stakeParam.positionOwner
        );
    }

    function _mintYieldTokensFromSY(
        address POT,
        uint256 amountInSY,
        uint256 lockupDays, 
        uint256 minPTGenerated,
        address PTRecipient, 
        address YTRecipient,
        address positionOwner
    ) internal returns (uint256 PTGenerated, uint256 YTGenerated) {
        (PTGenerated, YTGenerated) = IOutrunStakeManager(POT).stake(
            amountInSY, 
            lockupDays,
            PTRecipient, 
            YTRecipient, 
            positionOwner
        );

        require(PTGenerated >= minPTGenerated, InsufficientPTGenerated(PTGenerated, minPTGenerated));
    }

    /** REDEEM From Yield Tokens(PT, POT) **/
    function redeemYieldTokensToSy(
        address SY,
        address PT,
        address POT,
        address receiver,
        RedeemParam calldata redeemParam
    ) external returns (uint256 redeemedSyAmount) {
        uint256 share = redeemParam.positionShare;
        _transferFrom(IERC20(PT), msg.sender, address(this), share);

        uint256 positionId = redeemParam.positionId;
        _transferFrom(IERC1155(POT), msg.sender, address(this), positionId, share);

        redeemedSyAmount = IOutrunStakeManager(POT).redeem(positionId, share);
        uint256 minRedeemedSyAmount = redeemParam.minRedeemedSyAmount;
        require(redeemedSyAmount >= minRedeemedSyAmount, InsufficientSYRedeemed(redeemedSyAmount, minRedeemedSyAmount));
        
        _transferOut(SY, receiver, redeemedSyAmount);
    }
}
