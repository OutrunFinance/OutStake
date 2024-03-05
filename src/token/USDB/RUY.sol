// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRUY.sol";

/**
 * @title Outrun USD yield token
 */
contract RUY is IRUY, ERC20, Ownable {
    address private _RUSDStakeManager;

    modifier onlyRUSDStakeManager() {
        if (msg.sender != _RUSDStakeManager) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner) ERC20("Outrun USD yield token", "RUY") Ownable(owner) {}

    function RUSDStakeManager() external view override returns (address) {
        return _RUSDStakeManager;
    }

    /**
     * Only RUSDStakeManager can mint when the user stake RUSD
     * @param _account Address who stake RUSD 
     * @param _amount The amount of minted RUY
     */
    function mint(address _account, uint256 _amount) external override onlyRUSDStakeManager {
        _mint(_account, _amount);
    }

    /**
     * Only RUSDStakeManager can burn when the user redempt the native yield
     * @param _account Address who redempt the native yield
     * @param _amount The amount of burned RUY
     */
    function burn(address _account, uint256 _amount) external override onlyRUSDStakeManager {
        _burn(_account, _amount);
    }

    function setRUSDStakeManager(address _stakeManager) external override onlyOwner {
        _RUSDStakeManager = _stakeManager;
        emit SetRUSDStakeManager(_stakeManager);
    }
}