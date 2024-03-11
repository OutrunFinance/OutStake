// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IREY.sol";
import "../../utils/Initializable.sol";

/**
 * @title Outrun ETH yield token
 */
contract REY is IREY, ERC20, Initializable, Ownable {
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
     * @dev Initializer
     * @param stakeManager_ - Address of RETHStakeManager
     */
    function initialize(address stakeManager_) external override initializer {
        setRETHStakeManager(stakeManager_);
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

    function setRETHStakeManager(address _stakeManager) public override onlyOwner {
        _RETHStakeManager = _stakeManager;
        emit SetRETHStakeManager(_stakeManager);
    }
}