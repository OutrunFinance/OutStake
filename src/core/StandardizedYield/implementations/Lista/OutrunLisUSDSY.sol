// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../SYBaseWithRewards.sol";
import "../../../libraries/SYUtils.sol";
import "../../../libraries/ArrayLib.sol";
import "../../../../external/lista/IListaLisUSDJar.sol";
import "../../../../external/lista/IStakeLisUSDListaDistributor.sol";

contract OutrunLisUSDSY is SYBaseWithRewards {
    using ArrayLib for address[];

    IListaLisUSDJar public immutable listaLisUSDJar;
    IStakeLisUSDListaDistributor public immutable distributor;
    address public immutable defaultRewardToken;

    address[] public additionalRewardTokens;
    uint256 public totalDepositedInJar;

    constructor(
        address _owner,
        address _lisUSD,
        address _defaultRewardToken,
        IListaLisUSDJar _jar,
        IStakeLisUSDListaDistributor _distributor
    ) SYBaseWithRewards("SY Lista lisUSD", "SY-lisUSD", _lisUSD, _owner) {
        listaLisUSDJar = _jar;
        distributor = _distributor;
        defaultRewardToken = _defaultRewardToken;

        _safeApproveInf(nativeYieldToken, address(_jar));
    }

    function _deposit(
        address /*tokenIn*/,
        uint256 amountDeposited
    ) internal override returns (uint256 amountSharesOut) {
        listaLisUSDJar.join(amountDeposited);
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
        uint256 claimableYields = listaLisUSDJar.earned(address(this));
        uint256 totalAssets = totalDepositedInJar + claimableYields;
        totalAssets = totalAssets == 0 ? 1 : totalAssets; 
        uint256 totalShares = totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;
        amountTokenOut = amountSharesToRedeem * totalAssets / totalShares;

        listaLisUSDJar.exit(amountTokenOut);
        _transferOut(nativeYieldToken, receiver, amountTokenOut);
        listaLisUSDJar.join(claimableYields);

        unchecked {
            totalDepositedInJar = totalDepositedInJar - amountTokenOut + claimableYields;
        }
    }

    function exchangeRate() public view override returns (uint256 res) {
        uint256 totalAssets = totalDepositedInJar + listaLisUSDJar.earned(address(this));
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

    /**
     * @dev See {IStandardizedYield-getRewardTokens}
     */
    function _getRewardTokens() internal view override returns (address[] memory) {
        return additionalRewardTokens.appendHead(defaultRewardToken);
    }

    function _redeemExternalReward() internal override {
        distributor.claimReward();
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
