// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IREY.sol";

/**
 * @title Outrun ETH yield token
 */
contract REY is IREY, ERC20, Ownable {
    address public _RETHStakeManager;

    modifier onlyRETHStakeManager() {
        if (msg.sender != _RETHStakeManager) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner) ERC20("Outrun ETH yield token", "REY") Ownable(owner) {}

    function RETHStakeManager() external view override returns (address) {
        return _RETHStakeManager;
    }

    /**
     * Only RETHStakeManager can mint when the user stake RETH
     * @param _account Address who stake RETH 
     * @param _amount The amount of minted REY
     */
    function mint(address _account, uint256 _amount) external override onlyRETHStakeManager {
        _mint(_account, _amount);
    }

    /**
     * Only RETHStakeManager can burn when the user redempt the native yield
     * @param _account Address who redempt the native yield
     * @param _amount The amount of burned REY
     */
    function burn(address _account, uint256 _amount) external override onlyRETHStakeManager {
        _burn(_account, _amount);
    }

    function setRETHStakeManager(address _stakeManager) external override onlyOwner {
        _RETHStakeManager = _stakeManager;
        emit SetRETHStakeManager(_stakeManager);
    }
}