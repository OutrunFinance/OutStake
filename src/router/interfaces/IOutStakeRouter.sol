// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IOutStakeRouter {
    struct TokenInput {
        address tokenIn;
        uint256 amount;
        uint256 minTokenOut;
    }

    struct StakeParam {
        uint256 lockupDays;
        uint256 minPTGenerated;
        address PTRecipient;
        address YTRecipient;
        address positionOwner;
    }

    struct RedeemParam {
        uint256 positionId; 
        uint256 positionShare;
        uint256 minRedeemedSyAmount;
    }
    

    /** MINT/REDEEM SY **/
    function mintSYFromToken(
        address SY,
        address tokenIn,
        address receiver,
        uint256 amountInput,
        uint256 minSyOut
    ) external returns (uint256 amountInSYOut);

    function redeemSyToToken(
        address SY,
        address receiver,
        address tokenOut,
        uint256 amountInSY,
        uint256 minTokenOut
    ) external returns (uint256 amountInTokenOut);


    /** MINT Yield Tokens(PT, YT, POT) **/
    function mintYieldTokensFromToken(
        address SY,
        address POT,
        address tokenIn,
        uint256 tokenAmount,
        StakeParam calldata stakeParam
    ) external returns (uint256 PTGenerated, uint256 YTGenerated);

    function mintYieldTokensFromSY(
        address SY,
        address POT,
        uint256 amountInSY,
        StakeParam calldata stakeParam
    ) external returns (uint256 PTGenerated, uint256 YTGenerated);


    /** REDEEM From Yield Tokens(PT, POT) **/
    function redeemYieldTokensToSy(
        address SY,
        address PT,
        address POT,
        address receiver,
        RedeemParam calldata redeemParam
    ) external returns (uint256 redeemedSyAmount);

    error InsufficientPTGenerated(uint256 PTGenerated, uint256 minPTGenerated);

    error InsufficientSYRedeemed(uint256 redeemedSyAmount, uint256 minRedeemedSyAmount);
}
