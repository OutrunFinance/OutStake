// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title Bang USD yield token interface
  */
interface IBUYT is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setBUSDYieldPool(address _address) external;

    function setBUSDStakeManager(address _address) external;

    event Mint(address indexed _account, uint256 _amount);
    
    event SetBUSDYieldPool(address  _address);

    event SetBUSDStakeManager(address  _address);
}