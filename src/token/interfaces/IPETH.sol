// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

 /**
  * @title PETH interface
  */
interface IPETH {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function setETHStakeManager(address _address) external;

    event SetETHStakeManager(address _address);
}