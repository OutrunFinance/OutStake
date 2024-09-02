// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../SYBase.sol";
import "../../../../external/lista/IListaBNBStakeManager.sol";

contract OutrunSlisBNBSY is SYBase {
    address public immutable listaBNBStakeManager;
    address public immutable YT;

    constructor(
        address _owner,
        address _slisBNB,
        address _stakeManager
    ) SYBase("SY Lista slisBNB", "SY-slisBNB", _slisBNB, _owner) {
        listaBNBStakeManager = _stakeManager;
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        if (tokenIn == NATIVE) {
            IListaBNBStakeManager(listaBNBStakeManager).deposit{value: amountDeposited}();
            amountSharesOut = _selfBalance(nativeYieldToken);
        } else {
            amountSharesOut = amountDeposited;
        }
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        _transferOut(nativeYieldToken, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    function exchangeRate() public view override returns (uint256 res) {
        return IListaBNBStakeManager(listaBNBStakeManager).convertSnBnbToBnb(1 ether);
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        if (tokenIn == NATIVE) {
            amountSharesOut = IListaBNBStakeManager(listaBNBStakeManager).convertBnbToSnBnb(amountTokenToDeposit);
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
