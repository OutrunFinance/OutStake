// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IREY.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Outrun ETH yield token
 */
contract REY is IREY, ERC20, Ownable {
    address public RETHStakeManager;
    address public RETHYieldPool;

    constructor(address owner, address _RETHStakeManager, address _RETHYieldPool) ERC20("Outrun ETH yield token", "REY") Ownable(owner) {
        RETHStakeManager = _RETHStakeManager;
        RETHYieldPool = _RETHYieldPool;

        emit SetRETHYieldPool(_RETHYieldPool);
        emit SetRETHStakeManager(_RETHStakeManager);
    }

    function burn(address account, uint256 amount) external override {
        require(msg.sender == RETHYieldPool, "Access only by RETHYieldPool");
        require(amount > 0, "Invalid Amount");

        _burn(account, amount);
    }

    function mint(address _account, uint256 _amount) external override {
        require(msg.sender == RETHStakeManager, "Access only by RETHStakeManager");
        _mint(_account, _amount);
    }

    function setRETHYieldPool(address _RETHYieldPool) external override onlyOwner {
        RETHYieldPool = _RETHYieldPool;
        emit SetRETHYieldPool(_RETHYieldPool);
    }

    function setRETHStakeManager(address _RETHStakeManager) external override onlyOwner {
        RETHStakeManager = _RETHStakeManager;
        emit SetRETHStakeManager(_RETHStakeManager);
    }
}