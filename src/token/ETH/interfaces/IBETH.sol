// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title BETH interface
  */
interface IBETH is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setBnETHVault(address _address) external;
    
    event SetBnETHVault(address _address);
}