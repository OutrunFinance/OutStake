// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IPUSD.sol";
import "../../blast/GasManagerable.sol";
import "../../utils/Initializable.sol";

/**
 * @title Outrun Principal USD Liquid Staked Token
 */
contract PUSD is IPUSD, ERC20, Initializable, Ownable, GasManagerable {
    address private _RUSDStakeManager;

    modifier onlyRUSDStakeManager() {
        if (msg.sender != _RUSDStakeManager) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner, address gasManager) ERC20("Principal Staked USD", "PUSD") Ownable(owner) GasManagerable(gasManager) {}

    function RUSDStakeManager() external view override returns (address) {
        return _RUSDStakeManager;
    }

    /**
     * @dev Initializer
     * @param stakeManager_ - Address of RUSDStakeManager
     */
    function initialize(address stakeManager_) external override initializer {
        BLAST.configureClaimableGas();
        setRUSDStakeManager(stakeManager_);
    }

    /**
     * @dev Only RUSDStakeManager can mint when the user stake RUSD
     * @param _account Address who stake RUSD 
     * @param _amount The amount of deposited RUSD
     */
    function mint(address _account, uint256 _amount) external override onlyRUSDStakeManager{
        _mint(_account, _amount);
    }

    /**
     * @dev Only RUSDStakeManager can burn when the user redempt the RUSD 
     * @param _account Address who redempt the RUSD
     * @param _amount The amount of redempt RUSD
     */
    function burn(address _account, uint256 _amount) external override onlyRUSDStakeManager {
        _burn(_account, _amount);
    }

    function setRUSDStakeManager(address _stakeManager) public override onlyOwner {
        _RUSDStakeManager = _stakeManager;
        emit SetRUSDStakeManager(_stakeManager);
    }
}