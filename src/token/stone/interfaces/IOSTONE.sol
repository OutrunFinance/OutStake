// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title STONE principal token interface
  */
interface IOSTONE is IERC20 {
	error ZeroInput();

	error PermissionDenied();

	function stoneETHStakeManager() external view returns (address);

	function initialize(address stakeManager_) external;

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;

	function setStoneETHStakeManager(address _stakeManager) external;

	event SetStoneETHStakeManager(address _stakeManager);
}