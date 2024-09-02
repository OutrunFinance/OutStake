// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Outrun yield token interface
  */
interface IYieldToken is IERC20 {
	error ZeroInput();

	error PermissionDenied();

	function initialize(address _SY, address _positionOptionContract) external;
	
	function mint(address _account, uint256 _amount) external;
}