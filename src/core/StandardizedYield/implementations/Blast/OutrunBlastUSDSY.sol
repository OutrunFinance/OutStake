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
    address public immutable nrUSDB;

    constructor(
        address _USDB,
        address _nrUSDB,
        address _owner,
        address _gasManager,
        address _blastPoints,
        address _pointsOperator
    ) SYBase("SY Blast USD", "SY-USDB", _nrUSDB, _owner) GasManagerable(_gasManager) {
        USDB = _USDB;
        nrUSDB = _nrUSDB;
        IBlastPoints(_blastPoints).configurePointsOperator(_pointsOperator);

        _safeApprove(_USDB, _nrUSDB, type(uint256).max);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        amountSharesOut = tokenIn == nrUSDB ? amountDeposited : INrERC20(nrUSDB).wrap(amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        amountTokenOut = tokenOut == nrUSDB ? amountSharesToRedeem : INrERC20(nrUSDB).unwrap(amountSharesToRedeem);
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() public view override returns (uint256 res) {
        res = INrERC20(nrUSDB).stERC20PerToken();
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        amountSharesOut = tokenIn == nrUSDB ? amountTokenToDeposit : INrERC20(nrUSDB).getNrERC20ByStERC20(amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        amountTokenOut = tokenOut == nrUSDB ? amountSharesToRedeem : INrERC20(nrUSDB).getStERC20ByNrERC20(amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(USDB, nrUSDB);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(USDB, nrUSDB);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == USDB || token == nrUSDB;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == USDB || token == nrUSDB;
    }

    function assetInfo() external view returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, USDB, 18);
    }
}
