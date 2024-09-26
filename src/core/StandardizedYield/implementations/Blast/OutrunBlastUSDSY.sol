// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../SYBase.sol";
import "../../../libraries/SYUtils.sol";
import "../../../../external/IWETH.sol";
import "../../../../external/blast/INrERC20.sol";
import "../../../../external/blast/IBlastPoints.sol";
import "../../../../external/blast/GasManagerable.sol";

contract OutrunBlastUSDSY is SYBase, GasManagerable {
    address public immutable USDB;
    address public immutable nrUSD;

    constructor(
        address _owner,
        address _USDB,
        address _nrUSD,
        address _gasManager,
        address _blastPoints,
        address _pointsOperator
    ) SYBase("SY Blast USD", "SY-USDB", _nrUSD, _owner) GasManagerable(_gasManager) {
        USDB = _USDB;
        nrUSD = _nrUSD;
        IBlastPoints(_blastPoints).configurePointsOperator(_pointsOperator);

        _safeApprove(_USDB, _nrUSD, type(uint256).max);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        amountSharesOut = tokenIn == nrUSD ? amountDeposited : INrERC20(nrUSD).wrap(amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        amountTokenOut = tokenOut == nrUSD ? amountSharesToRedeem : INrERC20(nrUSD).unwrap(amountSharesToRedeem);
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() public view override returns (uint256 res) {
        res = INrERC20(nrUSD).stERC20PerToken();
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        amountSharesOut = tokenIn == nrUSD ? amountTokenToDeposit : INrERC20(nrUSD).getNrERC20ByStERC20(amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        amountTokenOut = tokenOut == nrUSD ? amountSharesToRedeem : INrERC20(nrUSD).getStERC20ByNrERC20(amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(USDB, nrUSD);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(USDB, nrUSD);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == USDB || token == nrUSD;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == USDB || token == nrUSD;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, USDB, 18);
    }
}
