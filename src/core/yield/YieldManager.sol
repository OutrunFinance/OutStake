// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../../core/yield/interfaces/IYieldManager.sol";

/**
 * With YT yielding more SYs overtime, which is allowed to be redeemed by users, the yields distribution
 * should be based on the amount of SYs that their YT currently represent
 */
abstract contract YieldManager is IYieldManager, Ownable {
    uint256 public constant RATIO = 10000;

    address public revenuePool;
    uint256 public protocolFeeRate;

    constructor(
        address owner_,
        address revenuePool_,
        uint256 protocolFeeRate_
    ) Ownable(owner_) {
        revenuePool = revenuePool_;
        protocolFeeRate = protocolFeeRate_;
    }

    /**
     * @dev Total redeemable  yields
     */
    function totalRedeemableYields() external view virtual returns (uint256 amount);

    /**
     * @dev Preview available yields
     * @param amountInBurnedYT - The amount of burned YT
     */
    function previewWithdrawYields(uint256 amountInBurnedYT) external view virtual returns (uint256 amountYieldsOut);

    /**
     * @dev Accumulate yields from POT
     */
    function accumulateYieldsFromPOT() external virtual {}

    /**
     * @dev Accumulate native yields, only SY contract can call.
     * @param amountInYields - The amount of native yields
     */
    function accumulateYieldsFromSY(address nativeYieldToken, uint256 amountInYields) external virtual {}

    /**
     * @dev Burn YT to withdraw yields
     * @param amountInBurnedYT - The amount of burned YT
     */
    function withdrawYields(uint256 amountInBurnedYT) external virtual returns (uint256 amountYieldsOut);

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
