// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../../SYUtils.sol";
import "../../OutrunYieldToken.sol";
import "../../interfaces/IStandardizedYield.sol";
import "../../../../core/common/IOutrunStakeManager.sol";

contract OutrunStoneYieldToken is OutrunYieldToken, ReentrancyGuard {
    uint256 public currentYields;

    constructor(
        address owner_,
        address _revenuePool,
        uint256 _protocolFeeRate
    ) OutrunYieldToken(
        "Outrun STONE Yield Token",
        "YT-STONE",
        18,
        owner_,
        _revenuePool,
        _protocolFeeRate
    ) {
    }

    function _latestYieldInfo() internal view returns (uint256 latestYield, uint256 increasedYield) {
        IOutrunStakeManager syStakeManager = IOutrunStakeManager(POT);
        uint256 exchangeRate = IStandardizedYield(SY).exchangeRate();
        uint256 totalCurrentAssetValue = SYUtils.syToAsset(exchangeRate, syStakeManager.syTotalStaking());
        uint256 totalPrincipalAssetValue = syStakeManager.totalPrincipalAssetValue();

        if (totalCurrentAssetValue > totalPrincipalAssetValue) {
            uint256 yieldInAsset = totalCurrentAssetValue - totalPrincipalAssetValue;
            latestYield = SYUtils.assetToSy(exchangeRate, yieldInAsset);
            uint256 _currentYields = currentYields;
            if (latestYield > _currentYields) {
                increasedYield = latestYield - _currentYields;
            }
        }
    }

    /**
     * @dev See {YieldManager-totalRedeemableYields}
     */
    function totalRedeemableYields() public view override returns (uint256 /*amount*/) {
        (uint256 latestYield, uint256 increasedYield) = _latestYieldInfo();
        if (increasedYield > 0) {
            unchecked {
                uint256 protocolFee = increasedYield * protocolFeeRate / RATIO;
                latestYield -= protocolFee;
            }
        }
        return latestYield;
    }

    /**
     * @dev See {YieldManager-previewWithdrawYields}
     */
    function previewWithdrawYields(uint256 amountInBurnedYT) public view override returns (uint256 amountYieldsOut) {
        amountYieldsOut = amountInBurnedYT * totalRedeemableYields() / totalSupply();
    }

    /**
     * @dev See {YieldManager-accumulateYieldsFromPOT}
     */
    function accumulateYieldsFromPOT() public override {
        (uint256 latestYield, uint256 increasedYield) = _latestYieldInfo();
        if (increasedYield > 0) {
            uint256 protocolFee;
            unchecked {
                protocolFee = increasedYield * protocolFeeRate / RATIO;
                latestYield -= protocolFee;
                currentYields = latestYield;
            }

            IOutrunStakeManager(POT).transferYields(revenuePool, protocolFee);
            emit AccumulateYields(increasedYield, protocolFee);
        }
    }

    /**
     * @dev See {YieldManager-withdrawYields}
     */
    function withdrawYields(uint256 amountInBurnedYT) external override nonReentrant returns (uint256 amountYieldsOut) {
        require(amountInBurnedYT != 0, ZeroInput());
        accumulateYieldsFromPOT();
        
        unchecked {
            amountYieldsOut = currentYields * amountInBurnedYT / totalSupply();
            currentYields -= amountYieldsOut;
        }

        address msgSender = msg.sender;
        _burn(msgSender, amountInBurnedYT);
        IOutrunStakeManager(POT).transferYields(msgSender, amountYieldsOut);

        emit WithdrawYields(msgSender, amountYieldsOut);
    }
}
