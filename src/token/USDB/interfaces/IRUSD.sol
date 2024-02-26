// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title RUSD interface
  */
interface IRUSD is IERC20 {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function mint(address _account, uint256 _amount) external;

    function setOutUSDBVault(address _outUSDBVault) external;
    
    event Deposit(address indexed _account, uint256 _amount);

    event Withdraw(address indexed _account, uint256 _amount);

    event SetOutUSDBVault(address _outUSDBVault);
}