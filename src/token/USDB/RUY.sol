// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRUY.sol";

/**
 * @title Outrun USD yield token
 */
contract RUY is IRUY, ERC20, Ownable {
    address public RUSDStakeManager;

    modifier onlyRUSDStakeManager() {
        if (msg.sender != RUSDStakeManager) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner) ERC20("Outrun USD yield token", "RUY") Ownable(owner) {}

    function burn(address account, uint256 amount) external override onlyRUSDStakeManager {
        if (amount == 0) {
            revert ZeroInput();
        }

        _burn(account, amount);
    }

    function mint(address _account, uint256 _amount) external override onlyRUSDStakeManager {
        _mint(_account, _amount);
    }

    function setRUSDStakeManager(address _RUSDStakeManager) external override onlyOwner {
        RUSDStakeManager = _RUSDStakeManager;
        emit SetRUSDStakeManager(_RUSDStakeManager);
    }
}