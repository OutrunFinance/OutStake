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
    address public BETHYieldPool;

    constructor(address owner, address _ETHStakeManager, address _BETHYieldPool) ERC20("Bang ETH yield token", "BEYT") Ownable(owner) {
        ETHStakeManager = _ETHStakeManager;
        BETHYieldPool = _BETHYieldPool;

        emit SetBETHYieldPool(_BETHYieldPool);
        emit SetETHStakeManager(_ETHStakeManager);
    }

    function burn(address account, uint256 amount) external override {
        require(msg.sender == BETHYieldPool, "Access only by BETHYieldPool");
        require(amount > 0, "Invalid Amount");

        _burn(account, amount);
    }

    function mint(address _account, uint256 _amount) external override {
        require(msg.sender == ETHStakeManager, "Access only by ETHStakeManager");
        _mint(_account, _amount);
    }

    function setBETHYieldPool(address _BETHYieldPool) external override onlyOwner {
        BETHYieldPool = _BETHYieldPool;
        emit SetBETHYieldPool(_BETHYieldPool);
    }

    function setETHStakeManager(address _ETHStakeManager) external override onlyOwner {
        ETHStakeManager = _ETHStakeManager;
        emit SetETHStakeManager(_ETHStakeManager);
    }
}