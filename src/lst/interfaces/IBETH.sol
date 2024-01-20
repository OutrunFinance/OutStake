// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

 /**
  * @title BETH interface
  */
interface IBETH {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setStakeManager(address _address) external;

    function stakeManager() external returns (address);

    event SetStakeManager(address indexed _address);
}