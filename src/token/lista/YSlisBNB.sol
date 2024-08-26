// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IYSlisBNB.sol";
import "../../utils/Initializable.sol";

/**
 * @title Outrun slisBNB yield token
 */
contract YSlisBNB is IYSlisBNB, ERC20, Initializable, Ownable {
    address public _listaBNBStakeManager;

    modifier onlyListaBNBStakeManager() {
        require(msg.sender == _listaBNBStakeManager, PermissionDenied());
        _;
    }

    constructor(address owner) ERC20("Outrun slisBNB yield token", "yslisBNB") Ownable(owner) {}

    function listaBNBStakeManager() external view override returns (address) {
        return _listaBNBStakeManager;
    }

    /**
     * @dev Initializer
     * @param stakeManager_ - Address of listaBNBStakeManager
     */
    function initialize(address stakeManager_) external override initializer {
        setListaBNBStakeManager(stakeManager_);
    }

    /**
     * @dev Only listaBNBStakeManager can mint when the user stake slisBNB
     * @param _account Address who stake slisBNB 
     * @param _amount The amount of minted yslisBNB
     */
    function mint(address _account, uint256 _amount) external override onlyListaBNBStakeManager {
        _mint(_account, _amount);
    }

    /**
     * @dev Only listaBNBStakeManager can burn when the user redempt the native yield
     * @param _account Address who redempt the native yield
     * @param _amount The amount of burned yslisBNB
     */
    function burn(address _account, uint256 _amount) external override onlyListaBNBStakeManager {
        _burn(_account, _amount);
    }

    function setListaBNBStakeManager(address _stakeManager) public override onlyOwner {
        _listaBNBStakeManager = _stakeManager;
        emit SetListaBNBStakeManager(_stakeManager);
    }
}