// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Outrun ETH yield token interface
  */
interface IREY is IERC20 {
    error ZeroInput();

    error PermissionDenied();

    function RETHStakeManager() external view returns (address);

    function initialize(address stakeManager_) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setRETHStakeManager(address _stakeManager) external;

    event Mint(address indexed _account, uint256 _amount);

    event SetRETHStakeManager(address  _stakeManager);
}