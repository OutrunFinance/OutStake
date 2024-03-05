// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPETH.sol";

/**
 * @title Outrun Principal ETH Liquid Staked Token
 */
contract PETH is IPETH, ERC20, Ownable {
    address private _RETHStakeManager;

    modifier onlyRETHStakeManager() {
        if (msg.sender != _RETHStakeManager) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner) ERC20("Principal Staked ETH", "PETH") Ownable(owner) {}

    function RETHStakeManager() external view override returns (address) {
        return _RETHStakeManager;
    }

    /**
     * Only RETHStakeManager can mint when the user stake RETH
     * @param _account Address who stake RETH 
     * @param _amount The amount of deposited RETH
     */
    function mint(address _account, uint256 _amount) external override onlyRETHStakeManager{
        _mint(_account, _amount);
    }

    /**
     * Only RETHStakeManager can burn when the user redempt the RETH 
     * @param _account Address who redempt the RETH
     * @param _amount The amount of redempt RETH
     */
    function burn(address _account, uint256 _amount) external override onlyRETHStakeManager {
        _burn(_account, _amount);
    }

    function setRETHStakeManager(address _stakeManager) external override onlyOwner {
        _RETHStakeManager = _stakeManager;
        emit SetRETHStakeManager(_stakeManager);
    }
}