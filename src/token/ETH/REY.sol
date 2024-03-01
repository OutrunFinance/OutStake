// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IREY.sol";

/**
 * @title Outrun ETH yield token
 */
contract REY is IREY, ERC20, Ownable {
    address public RETHStakeManager;

    modifier onlyRETHStakeManager() {
        require(msg.sender == RETHStakeManager, "Access only by RETHStakeManager");
        _;
    }

    constructor(address owner) ERC20("Outrun ETH yield token", "REY") Ownable(owner) {}

    function burn(address account, uint256 amount) external override onlyRETHStakeManager {
        require(amount > 0, "Invalid Amount");

        _burn(account, amount);
    }

    function mint(address _account, uint256 _amount) external override onlyRETHStakeManager {
        _mint(_account, _amount);
    }

    function setRETHStakeManager(address _RETHStakeManager) external override onlyOwner {
        RETHStakeManager = _RETHStakeManager;
        emit SetRETHStakeManager(_RETHStakeManager);
    }
}