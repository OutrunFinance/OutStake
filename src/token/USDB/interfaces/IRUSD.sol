// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title RUSD interface
  */
interface IRUSD is IERC20 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setOutUSDBVault(address _outUSDBVault) external;
    
    event SetOutUSDBVault(address _outUSDBVault);
}