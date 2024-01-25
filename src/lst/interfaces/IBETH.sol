// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

 /**
  * @title BETH interface
  */
interface IBETH {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setETHStakeManager(address _address) external;

    function ETHStakeManager() external returns (address);

    event SetETHStakeManager(address indexed _address);
}