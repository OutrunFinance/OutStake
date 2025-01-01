// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { SYBase, ArrayLib } from "../../SYBase.sol";
import { IMETHStaking } from "../../../../external/mantle/IMETHStaking.sol";

contract OutrunMETHSY is SYBase {
    constructor(
        address _owner,
        address _meth
    ) SYBase("SY Mantle mETH", "SY-mETH", _meth, _owner) {
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        if (tokenIn == NATIVE) {
            amountSharesOut = IMETHStaking(nativeYieldToken).ethToMETH(amountDeposited);
            IMETHStaking(nativeYieldToken).stake{value: amountDeposited}(amountSharesOut);
        } else {
            amountSharesOut = amountDeposited;
        }
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 /*amountTokenOut*/) {
        _transferOut(nativeYieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view override returns (uint256 res) {
        return IMETHStaking(nativeYieldToken).mETHToETH(1 ether);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == NATIVE) {
            amountSharesOut = IMETHStaking(nativeYieldToken).ethToMETH(amountTokenToDeposit);
        } else {
            amountSharesOut = amountTokenToDeposit;
        }
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(nativeYieldToken, NATIVE);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(nativeYieldToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == nativeYieldToken || token == NATIVE;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == nativeYieldToken;
    }

    function assetInfo() external pure returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, NATIVE, 18);
    }
}
