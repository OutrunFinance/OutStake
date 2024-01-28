// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./interfaces/IBETH.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Bang ETH Liquid Staked Token
 */
contract BETH is IBETH, ERC20, AccessControl {
    address private _ETHStakeManager;

    modifier onlyETHStakeManager() {
        require(
            msg.sender == _ETHStakeManager,
            "Accessible only by StakeManager Contract"
        );
        _;
    }

    constructor(address admin) ERC20("Bang ETH", "BETH") {
        require(admin != address(0), "Zero address provided");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function ETHStakeManager() public view virtual returns (address) {
        return _ETHStakeManager;
    }

    function setETHStakeManager(address _address) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        _ETHStakeManager = _address;
        emit SetETHStakeManager(_address);
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