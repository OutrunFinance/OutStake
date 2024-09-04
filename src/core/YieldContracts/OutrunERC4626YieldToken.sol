// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./OutrunYieldToken.sol";
import "./OutrunPrincipalToken.sol";
import "./interfaces/IYieldManager.sol";
import "../libraries/SYUtils.sol";
import "../StandardizedYield/IStandardizedYield.sol";
import "../Position/interfaces/IOutrunStakeManager.sol";


/**
 * With YT yielding more SYs overtime, which is allowed to be redeemed by users, the yields distribution
 * should be based on the amount of SYs that their YT currently represent
 */
contract OutrunERC4626YieldToken is IYieldManager, OutrunYieldToken, ReentrancyGuard, Ownable {
    uint256 public constant RATIO = 10000;

    address public revenuePool;
    uint256 public protocolFeeRate;
    uint256 public currentYields;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner_,
        address revenuePool_,
        uint256 protocolFeeRate_
    ) OutrunYieldToken(name_, symbol_, decimals_) Ownable(owner_) {
        revenuePool = revenuePool_;
        protocolFeeRate = protocolFeeRate_;
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
     * @dev Total redeemable yields
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
     * @dev Preview available yields
     * @param amountInBurnedYT - The amount of burned YT
     */
    function previewWithdrawYields(uint256 amountInBurnedYT) public view override returns (uint256 amountYieldsOut) {
        uint256 _totalSupply = totalSupply();
        require(amountInBurnedYT <= _totalSupply && _totalSupply > 0, InvalidInput());
        amountYieldsOut = amountInBurnedYT * totalRedeemableYields() / _totalSupply;
    }
    /**
     * @dev Accumulate yields
     */
    function accumulateYields() public override {
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
     * @dev Burn YT to withdraw yields
     * @param amountInBurnedYT - The amount of burned YT
     */
    function withdrawYields(uint256 amountInBurnedYT) external override nonReentrant returns (uint256 amountYieldsOut) {
        require(amountInBurnedYT != 0, ZeroInput());
        uint256 _totalSupply = totalSupply();
        require(amountInBurnedYT <= _totalSupply && _totalSupply > 0, InvalidInput());
        accumulateYields();

        unchecked {
            amountYieldsOut = currentYields * amountInBurnedYT / _totalSupply;
            currentYields -= amountYieldsOut;
        }

        address msgSender = msg.sender;
        _burn(msgSender, amountInBurnedYT);
        IOutrunStakeManager(POT).transferYields(msgSender, amountYieldsOut);

        emit WithdrawYields(msgSender, amountYieldsOut);
    }

    /**
     * @param _revenuePool - Address of revenue pool
     */
    function setRevenuePool(address _revenuePool) public override onlyOwner {
        revenuePool = _revenuePool;
        emit SetRevenuePool(_revenuePool);
    }

    /**
     * @param _protocolFeeRate - Protocol fee rate
     */
    function setProtocolFeeRate(uint256 _protocolFeeRate) public override onlyOwner {
        require(_protocolFeeRate <= RATIO, FeeRateOverflow());

        protocolFeeRate = _protocolFeeRate;
        emit SetProtocolFeeRate(_protocolFeeRate);
    }
}
