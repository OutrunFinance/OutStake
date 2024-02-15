// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Outrun USD yield token interface
  */
interface IRUYT is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setRUSDYieldPool(address _address) external;

    function setRUSDStakeManager(address _address) external;

    event Mint(address indexed _account, uint256 _amount);
    
    event SetRUSDYieldPool(address  _address);

    event SetRUSDStakeManager(address  _address);
}