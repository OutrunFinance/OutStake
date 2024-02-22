// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./interfaces/IRUY.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Outrun USD yield token
 */
contract RUY is IRUY, ERC20, Ownable {
    address public RUSDStakeManager;
    address public RUSDYieldPool;

    constructor(address owner) ERC20("Outrun USD yield token", "RUY") Ownable(owner) {}

    function burn(address account, uint256 amount) external override {
        require(msg.sender == RUSDYieldPool, "Access only by RUSDYieldPool");
        require(amount > 0, "Invalid Amount");

        _burn(account, amount);
    }

    function mint(address _account, uint256 _amount) external override {
        require(msg.sender == RUSDStakeManager, "Access only by RUSDStakeManager");
        _mint(_account, _amount);
    }

    function setRUSDYieldPool(address _RUSDYieldPool) external override onlyOwner {
        RUSDYieldPool = _RUSDYieldPool;
        emit SetRUSDYieldPool(_RUSDYieldPool);
    }

    function setRUSDStakeManager(address _RUSDStakeManager) external override onlyOwner {
        RUSDStakeManager = _RUSDStakeManager;
        emit SetRUSDStakeManager(_RUSDStakeManager);
    }
}