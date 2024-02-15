// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IPUSD.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Bang Principal USD Liquid Staked Token
 */
contract PUSD is IPUSD, ERC20, Ownable {
    address public BUSDStakeManager;

    modifier onlyBUSDStakeManager() {
        require(
            msg.sender == BUSDStakeManager,
            "Access only by StakeManager"
        );
        _;
    }

    constructor(address owner, address _BUSDStakeManager) ERC20("Principal Staked USD", "PUSD") Ownable(owner) {
        BUSDStakeManager = _BUSDStakeManager;
        emit SetBUSDStakeManager(_BUSDStakeManager);
    }

    function setBUSDStakeManager(address _BUSDStakeManager) external override onlyOwner {
        require(_BUSDStakeManager != address(0), "Zero address provided");

        BUSDStakeManager = _BUSDStakeManager;
        emit SetBUSDStakeManager(_BUSDStakeManager);
    }

    /**
     * Only BUSDStakeManager can mint when the user deposit BUSD
     * @param _account Address who deposit BUSD 
     * @param _amount The amount of deposited BUSD
     */
    function mint(address _account, uint256 _amount) external override onlyBUSDStakeManager{
        _mint(_account, _amount);
    }

    /**
     * Only BUSDStakeManager can burn when the user redempt the BUSD 
     * @param _account Address who redempt the BUSD
     * @param _amount The amount of redempt BUSD
     */
    function burn(address _account, uint256 _amount) external override onlyBUSDStakeManager {
        _burn(_account, _amount);
    }
}