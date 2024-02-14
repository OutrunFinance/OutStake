// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IBEYT.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Bang ETH yield token
 */
contract BEYT is IBEYT, ERC20, Ownable {
    address public ETHStakeManager;
    address public ETHYieldPool;

    constructor(address owner, address _ETHStakeManager, address _ETHYieldPool) ERC20("Bang ETH yield token", "BEYT") Ownable(owner) {
        ETHStakeManager = _ETHStakeManager;
        ETHYieldPool = _ETHYieldPool;

        emit SetETHYieldPool(_ETHYieldPool);
        emit SetETHStakeManager(_ETHStakeManager);
    }

    function burn(address account, uint256 amount) external override {
        require(msg.sender == ETHYieldPool, "Access only by ETHYieldPool");
        require(amount > 0, "Invalid Amount");

        _burn(account, amount);
    }

    function mint(address _account, uint256 _amount) external override {
        require(msg.sender == ETHStakeManager, "Access only by ETHStakeManager");
        _mint(_account, _amount);
    }

    function setETHYieldPool(address _ETHYieldPool) external override onlyOwner {
        ETHYieldPool = _ETHYieldPool;
        emit SetETHYieldPool(_ETHYieldPool);
    }

    function setETHStakeManager(address _ETHStakeManager) external override onlyOwner {
        ETHStakeManager = _ETHStakeManager;
        emit SetETHStakeManager(_ETHStakeManager);
    }
}