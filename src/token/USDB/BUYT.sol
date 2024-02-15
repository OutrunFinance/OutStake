// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IBUYT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Bang USD yield token
 */
contract BUYT is IBUYT, ERC20, Ownable {
    address public BUSDStakeManager;
    address public BUSDYieldPool;

    constructor(address owner, address _BUSDStakeManager, address _BUSDYieldPool) ERC20("Bang USD yield token", "BUYT") Ownable(owner) {
        BUSDStakeManager = _BUSDStakeManager;
        BUSDYieldPool = _BUSDYieldPool;

        emit SetBUSDYieldPool(_BUSDYieldPool);
        emit SetBUSDStakeManager(_BUSDStakeManager);
    }

    function burn(address account, uint256 amount) external override {
        require(msg.sender == BUSDYieldPool, "Access only by BUSDYieldPool");
        require(amount > 0, "Invalid Amount");

        _burn(account, amount);
    }

    function mint(address _account, uint256 _amount) external override {
        require(msg.sender == BUSDStakeManager, "Access only by BUSDStakeManager");
        _mint(_account, _amount);
    }

    function setBUSDYieldPool(address _BUSDYieldPool) external override onlyOwner {
        BUSDYieldPool = _BUSDYieldPool;
        emit SetBUSDYieldPool(_BUSDYieldPool);
    }

    function setBUSDStakeManager(address _BUSDStakeManager) external override onlyOwner {
        BUSDStakeManager = _BUSDStakeManager;
        emit SetBUSDStakeManager(_BUSDStakeManager);
    }
}