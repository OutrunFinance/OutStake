// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

interface INrERC20 {
    function getNrERC20ByStERC20(uint256 amount) external view returns (uint256);

    function getStERC20ByNrERC20(uint256 shares) external view returns (uint256);

    function stERC20PerToken() external view returns (uint256);

    function wrap(uint256 amount) external returns (uint256);

    function unwrap(uint256 shares) external returns (uint256);
}