// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Bang ETH yield token interface
  */
interface IBEYT is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setETHYieldPool(address _address) external;

    function setETHStakeManager(address _address) external;

    event Mint(address indexed _account, uint256 _amount);
    
    event SetETHYieldPool(address  _address);

    event SetETHStakeManager(address  _address);
}