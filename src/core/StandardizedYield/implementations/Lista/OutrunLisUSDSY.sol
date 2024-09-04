// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../SYBase.sol";
import "../../../libraries/SYUtils.sol";
import "../../../../external/lista/IListaLisUSDJar.sol";

contract OutrunLisUSDSY is SYBase {
    address public immutable listaLisUSDJar;
    address public immutable YT;

    uint256 public totalDepositedInJar;

    constructor(
        address _owner,
        address _lisUSD,
        address _jar,
        address _YT
    ) SYBase("SY Lista lisUSD", "SY-lisUSD", _lisUSD, _owner) {
        listaLisUSDJar = _jar;
        YT = _YT;

        _safeApproveInf(nativeYieldToken, _jar);
        _safeApproveInf(nativeYieldToken, _YT);
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        IListaLisUSDJar(listaLisUSDJar).join(amountDeposited);
        unchecked {
            totalDepositedInJar += amountDeposited;
        }
        amountSharesOut = SYUtils.assetToSy(exchangeRate(), amountDeposited);
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        uint256 claimableYields = IListaLisUSDJar(listaLisUSDJar).earned(address(this));
        uint256 totalAssets = totalDepositedInJar + claimableYields;
        uint256 totalShares = totalSupply() + amountSharesToRedeem;
        amountTokenOut = amountSharesToRedeem * totalAssets / totalShares;

        IListaLisUSDJar(listaLisUSDJar).exit(amountTokenOut);
        _transferOut(nativeYieldToken, receiver, amountTokenOut);
        IListaLisUSDJar(listaLisUSDJar).join(claimableYields);

        unchecked {
            totalDepositedInJar = totalDepositedInJar - amountTokenOut + claimableYields;
        }
    }

    function exchangeRate() public view override returns (uint256 res) {
        uint256 totalAssets = totalDepositedInJar + IListaLisUSDJar(listaLisUSDJar).earned(address(this));
        totalAssets = totalAssets == 0 ? 1 : totalAssets; 

        uint256 totalShares = totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;
 
        res = (1e18 * totalAssets) / totalShares;
    }

    function _previewDeposit(
        address /*tokenIn*/,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        return SYUtils.assetToSy(exchangeRate(), amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 /*amountTokenOut*/) {
        return SYUtils.syToAsset(exchangeRate(), amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(nativeYieldToken);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(nativeYieldToken);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == nativeYieldToken;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == nativeYieldToken;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, nativeYieldToken, IERC20Metadata(nativeYieldToken).decimals());
    }
}
