// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title OSUSD interface
  */
interface IOSUSD is IERC20 {
    error ZeroInput();

    error PermissionDenied();

    function ORUSDStakeManager() external view returns (address);

    function initialize(address stakeManager_) external;
    
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setORUSDStakeManager(address _stakeManager) external;

    event SetORUSDStakeManager(address _stakeManager);
}