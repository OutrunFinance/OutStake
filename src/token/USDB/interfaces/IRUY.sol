// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Outrun USD yield token interface
  */
interface IRUY is IERC20 {
    error ZeroInput();

    error PermissionDenied();

    function RUSDStakeManager() external view returns (address);

    function initialize(address stakeManager_) external;
    
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setRUSDStakeManager(address _stakeManager) external;

    event Mint(address indexed _account, uint256 _amount);

    event SetRUSDStakeManager(address  _stakeManager);
}