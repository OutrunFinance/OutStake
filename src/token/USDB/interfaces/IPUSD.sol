// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title IPUSD interface
  */
interface IPUSD is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setUSDBStakeManager(address _address) external;

    function USDBStakeManager() external returns (address);

    event SetUSDBStakeManager(address indexed _address);
}