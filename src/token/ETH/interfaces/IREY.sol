// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Outrun ETH yield token interface
  */
interface IREY is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setRETHYieldPool(address _address) external;

    function setRETHStakeManager(address _address) external;

    event Mint(address indexed _account, uint256 _amount);
    
    event SetRETHYieldPool(address  _address);

    event SetRETHStakeManager(address  _address);
}