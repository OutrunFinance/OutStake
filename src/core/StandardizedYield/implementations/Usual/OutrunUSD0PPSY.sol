// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { IUsd0PP } from "../../../../external/usual/IUsd0PP.sol";
import { SYBase, IERC20Metadata, ArrayLib } from "../../SYBase.sol";

contract OutrunUSD0PPSY is SYBase {
    address public immutable USD0;

    constructor(
        address _owner,
        address _usd0,
        address _usd0PP
    ) SYBase("SY Usual USD0++", "SY-USD0++", _usd0PP, _owner) {
        USD0 = _usd0;
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == USD0) {
            IUsd0PP(yieldBearingToken).mint(amountDeposited);
        }
        
        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        _transferOut(yieldBearingToken, receiver, amountSharesToRedeem);
        amountTokenOut = amountSharesToRedeem;
    }

    function exchangeRate() public pure override returns (uint256 res) {
        return 1e18;
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal pure override returns (uint256 /*amountSharesOut*/) {
        return amountTokenToDeposit;
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldBearingToken, USD0);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(yieldBearingToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == yieldBearingToken || token == USD0;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == yieldBearingToken;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, USD0, IERC20Metadata(USD0).decimals());
    }
}
