// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPETH.sol";

/**
 * @title Outrun Principal ETH Liquid Staked Token
 */
contract PETH is IPETH, ERC20, Ownable {
    address public RETHStakeManager;

    modifier onlyRETHStakeManager() {
        require(
            msg.sender == RETHStakeManager,
            "Access only by StakeManager"
        );
        _;
    }

    constructor(address owner) ERC20("Principal Staked ETH", "PETH") Ownable(owner) {}

    function setRETHStakeManager(address _RETHStakeManager) external override onlyOwner {
        require(_RETHStakeManager != address(0), "Zero address provided");

        RETHStakeManager = _RETHStakeManager;
        emit SetRETHStakeManager(_RETHStakeManager);
    }

    /**
     * Only RETHStakeManager can mint when the user deposit RETH
     * @param _account Address who deposit RETH 
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
}