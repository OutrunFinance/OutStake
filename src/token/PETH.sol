// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./interfaces/IPETH.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Bang Principal ETH Liquid Staked Token
 */
contract PETH is IPETH, ERC20, Ownable {
    address public ETHStakeManager;

    modifier onlyETHStakeManager() {
        require(
            msg.sender == ETHStakeManager,
            "Access only by StakeManager"
        );
        _;
    }

    constructor(address owner, address _ETHStakeManager) ERC20("Principal Staked ETH", "PETH") Ownable(owner) {
        require(_ETHStakeManager != address(0), "Zero address provided");

        ETHStakeManager = _ETHStakeManager;

        emit SetETHStakeManager(_ETHStakeManager);
    }

    function setETHStakeManager(address _ETHStakeManager) external override onlyOwner {
        require(_ETHStakeManager != address(0), "Zero address provided");

        ETHStakeManager = _ETHStakeManager;

        emit SetETHStakeManager(_ETHStakeManager);
    }

    /**
     * Only ETHStakeManager can mint when the user deposit ETH
     * @param _account Address who deposit ETH 
     * @param _amount The amount of deposited ETH
     */
    function mint(address _account, uint256 _amount) external override onlyETHStakeManager{
        _mint(_account, _amount);
    }

    /**
     * Only ETHStakeManager can burn when the user redempt the ETH 
     * @param _account Address who redempt the ETH
     * @param _amount The amount of redempt ETH
     */
    function burn(address _account, uint256 _amount) external override onlyETHStakeManager {
        _burn(_account, _amount);
    }
}