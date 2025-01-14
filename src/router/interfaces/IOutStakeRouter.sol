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

    struct MintUPTParam {
        address PT;
        address UPT;
    }
    

    /** MINT/REDEEM SY **/
    function mintSYFromToken(
        address SY,
        address tokenIn,
        address receiver,
        uint256 amountInput,
        uint256 minSyOut,
        bool doPull
    ) external payable returns (uint256 amountInSYOut);

    function redeemSyToToken(
        address SY,
        address receiver,
        address tokenOut,
        uint256 amountInSY,
        uint256 minTokenOut,
        bool doPull
    ) external returns (uint256 amountInTokenOut);


    /** MINT PT(UPT), YT, POT Tokens **/
    function mintPPYFromToken(
        address SY,
        address POT,
        address tokenIn,
        uint256 tokenAmount,
        StakeParam calldata stakeParam,
        MintUPTParam calldata mintUPTParam
    ) external payable returns (uint256 PTGenerated, uint256 YTGenerated);

    function mintPPYFromSY(
        address SY,
        address POT,
        uint256 amountInSY,
        StakeParam calldata stakeParam,
        MintUPTParam calldata mintUPTParam
    ) external returns (uint256 PTGenerated, uint256 YTGenerated);


    /** REDEEM From PT, POT **/
    function redeemPPToSy(
        address SY,
        address PT,
        address UPT,
        address POT,
        address receiver,
        RedeemParam calldata redeemParam
    ) external returns (uint256 redeemedSyAmount);

    function redeemPPToToken(
        address SY,
        address PT,
        address UPT,
        address POT,
        address tokenOut,
        address receiver,
        RedeemParam calldata redeemParam
    ) external returns (uint256 redeemedSyAmount);

    error InsufficientPTGenerated(uint256 PTGenerated, uint256 minPTGenerated);

    error InsufficientSYRedeemed(uint256 redeemedSyAmount, uint256 minRedeemedSyAmount);
}
