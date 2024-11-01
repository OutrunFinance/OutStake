// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { IOutStakeRouter } from "./interfaces/IOutStakeRouter.sol";
import { TokenHelper, IERC20, IERC1155 } from "../core/libraries/TokenHelper.sol";
import { IStandardizedYield } from "../core/StandardizedYield/IStandardizedYield.sol";
import { IOutrunStakeManager } from "../core/Position/interfaces/IOutrunStakeManager.sol";
import { IUniversalPrincipalToken } from "../core/YieldContracts/interfaces/IUniversalPrincipalToken.sol";

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

    /** MINT PT(UPT), YT, POT Tokens **/
    function mintPPYFromToken(
        address SY,
        address POT,
        address tokenIn,
        uint256 tokenAmount,
        StakeParam calldata stakeParam,
        MintUPTParam calldata mintUPTParam
    ) external payable returns (uint256 PTGenerated, uint256 YTGenerated) {
        _transferIn(tokenIn, msg.sender, tokenAmount);
        uint256 amountInSY = _mintSY(SY, tokenIn, address(this), tokenAmount, 0);

        _safeApproveInf(SY, POT);
        (PTGenerated, YTGenerated) = _mintPPYFromSY(
            POT,
            amountInSY, 
            stakeParam,
            mintUPTParam
        );
    }

    function mintPPYFromSY(
        address SY,
        address POT,
        uint256 amountInSY,
        StakeParam calldata stakeParam,
        MintUPTParam calldata mintUPTParam
    ) external returns (uint256 PTGenerated, uint256 YTGenerated) {
        _transferFrom(IERC20(SY), msg.sender, address(this), amountInSY);

        _safeApproveInf(SY, POT);
        (PTGenerated, YTGenerated) = _mintPPYFromSY(
            POT,
            amountInSY, 
            stakeParam,
            mintUPTParam
        );
    }

    function _mintPPYFromSY(
        address POT,
        uint256 amountInSY,
        StakeParam calldata stakeParam,
        MintUPTParam calldata mintUPTParam
    ) internal returns (uint256 PTGenerated, uint256 YTGenerated) {
        address UPT = mintUPTParam.UPT;

        (PTGenerated, YTGenerated) = IOutrunStakeManager(POT).stake(
            amountInSY, 
            stakeParam.lockupDays,
            UPT == address(0) ? stakeParam.PTRecipient : address(this),
            stakeParam.YTRecipient, 
            stakeParam.positionOwner
        );

        if (UPT != address(0)) IUniversalPrincipalToken(UPT).mintUPTFromPT(mintUPTParam.PT, msg.sender, PTGenerated);

        uint256 minPTGenerated = stakeParam.minPTGenerated;
        require(PTGenerated >= minPTGenerated, InsufficientPTGenerated(PTGenerated, minPTGenerated));
    }

    /** REDEEM From PT, POT **/
    function redeemPPToSy(
        address SY,
        address PT,
        address UPT,
        address POT,
        address receiver,
        RedeemParam calldata redeemParam
    ) external returns (uint256 redeemedSyAmount) {
        uint256 share = redeemParam.positionShare;

        if (UPT != address(0)) {
            _transferFrom(IERC20(UPT), msg.sender, address(this), share);
            IUniversalPrincipalToken(UPT).redeemPTFromUPT(PT, address(this), share);
        } else {
            _transferFrom(IERC20(PT), msg.sender, address(this), share);
        }

        uint256 positionId = redeemParam.positionId;
        _transferFrom(IERC1155(POT), msg.sender, address(this), positionId, share);

        redeemedSyAmount = IOutrunStakeManager(POT).redeem(positionId, share);
        uint256 minRedeemedSyAmount = redeemParam.minRedeemedSyAmount;
        require(redeemedSyAmount >= minRedeemedSyAmount, InsufficientSYRedeemed(redeemedSyAmount, minRedeemedSyAmount));
        
        _transferOut(SY, receiver, redeemedSyAmount);
    }
}
