// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../SYBase.sol";
import "./interfaces/IOutrunLisUSDSY.sol";
import "../../interfaces/IYieldManager.sol";
import "../../../../external/lista/IListaLisUSDJar.sol";

contract OutrunLisUSDSY is IOutrunLisUSDSY, SYBase {
    address public immutable listaLisUSDJar;
    address public immutable YT;

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

    function replenishYieldBalance() external override {
        IListaLisUSDJar(listaLisUSDJar).exit(0);
        IYieldManager(YT).accumulateYieldsFromSY(nativeYieldToken, _selfBalance(nativeYieldToken));
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal override returns (uint256 /*amountSharesOut*/) {
        IListaLisUSDJar(listaLisUSDJar).join(amountDeposited);

        return amountDeposited;
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256) {
        IListaLisUSDJar(listaLisUSDJar).exit(amountSharesToRedeem);
        address _nativeYieldToken = nativeYieldToken;
        _transferOut(_nativeYieldToken, receiver, amountSharesToRedeem);
        uint256 amountInYields = _selfBalance(_nativeYieldToken);
        IYieldManager(YT).accumulateYieldsFromSY(nativeYieldToken, amountInYields);
        
        return amountSharesToRedeem;
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
