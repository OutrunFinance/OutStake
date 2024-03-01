// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPUSD.sol";

/**
 * @title Outrun Principal USD Liquid Staked Token
 */
contract PUSD is IPUSD, ERC20, Ownable {
    address public RUSDStakeManager;

    modifier onlyRUSDStakeManager() {
        if (msg.sender != RUSDStakeManager) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner) ERC20("Principal Staked USD", "PUSD") Ownable(owner) {}

    function setRUSDStakeManager(address _RUSDStakeManager) external override onlyOwner {
        if (_RUSDStakeManager == address(0)) {
            revert ZeroInput();
        }

        RUSDStakeManager = _RUSDStakeManager;
        emit SetRUSDStakeManager(_RUSDStakeManager);
    }

    /**
     * Only RUSDStakeManager can mint when the user deposit RUSD
     * @param _account Address who deposit RUSD 
     * @param _amount The amount of deposited RUSD
     */
    function mint(address _account, uint256 _amount) external override onlyRUSDStakeManager{
        _mint(_account, _amount);
    }

    /**
     * Only RUSDStakeManager can burn when the user redempt the RUSD 
     * @param _account Address who redempt the RUSD
     * @param _amount The amount of redempt RUSD
     */
    function burn(address _account, uint256 _amount) external override onlyRUSDStakeManager {
        _burn(_account, _amount);
    }
}