//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface IListaLisUSDJar {
    function earned(address account) external view returns (uint256);

    function join(uint256 wad) external;

    function exit(uint256 wad) external;
}