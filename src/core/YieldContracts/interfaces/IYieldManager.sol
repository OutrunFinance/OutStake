// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;
 
interface IYieldManager {
	error FeeRateOverflow();
	
	function totalRedeemableYields() external view returns (uint256 amount);

	function previewWithdrawYields(uint256 amountInBurnedYT) external view returns (uint256 amountYieldsOut);

	function accumulateYields() external;

	function withdrawYields(uint256 amountInBurnedYT) external returns (uint256 amountYieldsOut);

	function setRevenuePool(address revenuePool) external;

    function setProtocolFeeRate(uint256 protocolFeeRate) external;

	event AccumulateYields(uint256 amountInYields, uint256 protocolFee);

	event WithdrawYields(address account, uint256 amountYieldsOut);

	event SetRevenuePool(address revenuePool);
	
    event SetProtocolFeeRate(uint256 protocolFeeRate);
}