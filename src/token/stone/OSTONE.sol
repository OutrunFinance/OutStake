// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IOSTONE.sol";
import "../../utils/Initializable.sol";

/**
 * @title Outrun STONE principal token
 */
contract OSTONE is IOSTONE, ERC20, Initializable, Ownable {
    address private _stoneETHStakeManager;

    modifier onlyStoneETHStakeManager() {
        require(msg.sender == _stoneETHStakeManager, PermissionDenied());
        _;
    }

    constructor(address owner) ERC20("Outrun STONE principal token", "oSTONE") Ownable(owner) {}

    function stoneETHStakeManager() external view override returns (address) {
        return _stoneETHStakeManager;
    }

    /**
     * @dev Initializer
     * @param stakeManager_ - Address of stoneETHStakeManager
     */
    function initialize(address stakeManager_) external override initializer {
        setStoneETHStakeManager(stakeManager_);
    }

    /**
     * @dev Only stoneETHStakeManager can mint when the user stake STONE
     * @param _account Address who stake STONE 
     * @param _amount The amount of deposited STONE
     */
    function mint(address _account, uint256 _amount) external override onlyStoneETHStakeManager{
        _mint(_account, _amount);
    }

    /**
     * @dev Only stoneETHStakeManager can burn when the user redempt the STONE 
     * @param _account Address who redempt the STONE
     * @param _amount The amount of redempt STONE
     */
    function burn(address _account, uint256 _amount) external override onlyStoneETHStakeManager {
        _burn(_account, _amount);
    }

    function setStoneETHStakeManager(address _stakeManager) public override onlyOwner {
        _stoneETHStakeManager = _stakeManager;
        emit SetStoneETHStakeManager(_stakeManager);
    }
}