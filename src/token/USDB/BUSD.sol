// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IBUSD.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Bang USDB Liquid Staked Token
 */
contract BUSD is IBUSD, ERC20, AccessControl {
    address private _USDBStakeManager;

    modifier onlyUSDBStakeManager() {
        require(
            msg.sender == _USDBStakeManager,
            "Accessible only by StakeManager Contract"
        );
        _;
    }

    constructor(address USDBStakeManager_) ERC20("Bang USDB", "BUSD") {
        _USDBStakeManager = USDBStakeManager_;
    }

    function USDBStakeManager() public view virtual returns (address) {
        return _USDBStakeManager;
    }

    function setUSDBStakeManager(address _address) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        _USDBStakeManager = _address;
        emit SetUSDBStakeManager(_address);
    }

    /**
     * Only USDBStakeManager can mint when the user deposit USDB
     * @param _account Address who deposit USDB 
     * @param _amount The amount of deposited USDB
     */
    function mint(address _account, uint256 _amount) external override onlyUSDBStakeManager{
        _mint(_account, _amount);
    }

    /**
     * Only USDBStakeManager can burn when the user redempt the USDB 
     * @param _account Address who redempt the USDB
     * @param _amount The amount of redempt USDB
     */
    function burn(address _account, uint256 _amount) external override onlyUSDBStakeManager {
        _burn(_account, _amount);
    }
}