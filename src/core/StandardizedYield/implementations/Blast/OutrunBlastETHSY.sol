// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { SYBase, ArrayLib } from "../../SYBase.sol";
import { SYUtils } from "../../../libraries/SYUtils.sol";
import { IWETH } from "../../../../external/IWETH.sol";
import { INrERC20 } from "../../../../external/blast/INrERC20.sol";
import { IBlastPoints } from "../../../../external/blast/IBlastPoints.sol";
import { GasManagerable } from "../../../../external/blast/GasManagerable.sol";

contract OutrunBlastETHSY is SYBase, GasManagerable {
    address public immutable WETH;
    address public immutable nrETH;

    constructor(
        address _WETH,
        address _nrETH,
        address _owner,
        address _gasManager,
        address _blastPoints,
        address _pointsOperator
    ) SYBase("SY Blast ETH", "SY-BETH", _nrETH, _owner) GasManagerable(_gasManager) {
        WETH = _WETH;
        nrETH = _nrETH;
        IBlastPoints(_blastPoints).configurePointsOperator(_pointsOperator);

        _safeApprove(_WETH, _nrETH, type(uint256).max);
    }

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        if (tokenIn == NATIVE) IWETH(WETH).deposit{value: amountDeposited}();
        amountSharesOut = tokenIn == nrETH ? amountDeposited : INrERC20(nrETH).wrap(amountDeposited);
    }

    function _redeem(
        address receiver,
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal override returns (uint256 amountTokenOut) {
        amountTokenOut = tokenOut == nrETH ? amountSharesToRedeem : INrERC20(nrETH).unwrap(amountSharesToRedeem);
        if (tokenOut == NATIVE) IWETH(WETH).withdraw(amountTokenOut);
        _transferOut(tokenOut, receiver, amountTokenOut);
    }

    function exchangeRate() public view override returns (uint256 res) {
        res = INrERC20(nrETH).stERC20PerToken();
    }

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 amountSharesOut) {
        amountSharesOut = tokenIn == nrETH ? amountTokenToDeposit : INrERC20(nrETH).getNrERC20ByStERC20(amountTokenToDeposit);
    }

    function _previewRedeem(
        address tokenOut,
        uint256 amountSharesToRedeem
    ) internal view override returns (uint256 amountTokenOut) {
        amountTokenOut = tokenOut == nrETH ? amountSharesToRedeem : INrERC20(nrETH).getStERC20ByNrERC20(amountSharesToRedeem);
    }

    function getTokensIn() public view override returns (address[] memory res) {
        return ArrayLib.create(WETH, NATIVE, nrETH);
    }

    function getTokensOut() public view override returns (address[] memory res) {
        return ArrayLib.create(WETH, NATIVE, nrETH);
    }

    function isValidTokenIn(address token) public view override returns (bool) {
        return token == WETH || token == NATIVE || token == nrETH;
    }

    function isValidTokenOut(address token) public view override returns (bool) {
        return token == WETH || token == NATIVE || token == nrETH;
    }

    function assetInfo() external pure returns (AssetType assetType, address assetAddress, uint8 assetDecimals) {
        return (AssetType.TOKEN, NATIVE, 18);
    }
}
