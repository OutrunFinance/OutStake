// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Outrun principal token interface
  */
interface IPrincipalToken is IERC20 {
	error ZeroInput();

	error PermissionDenied();

	function setAuthList(address authContract, bool authorized) external;

	function mint(address account, uint256 amount) external;

	function burn(address account, uint256 amount) external;
}