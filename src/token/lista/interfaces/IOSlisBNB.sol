// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title slisBNB principal token interface
  */
interface IOSlisBNB is IERC20 {
	error ZeroInput();

	error PermissionDenied();

	function listaBNBStakeManager() external view returns (address);

	function initialize(address stakeManager_) external;

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;

	function setListaBNBStakeManager(address _stakeManager) external;

	event SetListaBNBStakeManager(address _stakeManager);
}