// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IYSTONE.sol";
import "../../utils/Initializable.sol";

/**
 * @title Outrun STONE yield token
 */
contract YSTONE is IYSTONE, ERC20, Initializable, Ownable {
    address public _stoneETHStakeManager;

    modifier onlyStoneETHStakeManager() {
        require(msg.sender == _stoneETHStakeManager, PermissionDenied());
        _;
    }

    constructor(address owner) ERC20("Outrun STONE yield token", "YSTONE") Ownable(owner) {}

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
     * @param _amount The amount of minted YSTONE
     */
    function mint(address _account, uint256 _amount) external override onlyStoneETHStakeManager {
        _mint(_account, _amount);
    }

    /**
     * @dev Only stoneETHStakeManager can burn when the user redempt the native yield
     * @param _account Address who redempt the native yield
     * @param _amount The amount of burned YSTONE
     */
    function burn(address _account, uint256 _amount) external override onlyStoneETHStakeManager {
        _burn(_account, _amount);
    }

    function setStoneETHStakeManager(address _stakeManager) public override onlyOwner {
        _stoneETHStakeManager = _stakeManager;
        emit SetStoneETHStakeManager(_stakeManager);
    }
}