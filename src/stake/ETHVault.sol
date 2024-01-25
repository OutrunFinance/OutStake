//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IVault} from "./interfaces/IVault.sol";
import {IBETH} from "../lst/interfaces/IBETH.sol";
import "../utils/Pausable.sol";

/**
 * @title ETH Vault Contract
 * @dev Handles Staking of BNB on BSC
 */
contract ETHVault is IETHVault, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    bytes32 public constant BOT = keccak256("BOT");

    address public ETHStakeManager;
    address public revenuePool;
    uint256 public feeRate; // range {0-1000}

    modifier onlyETHStakeManager() {
        require(
            msg.sender == ETHStakeManager,
            "Accessible only by ETHStakeManager"
        );
        _;
    }

    /**
     * @param _admin - Address of the admin
     * @param _bot - Address of the Bot
     * @param _feeRate - Rewards fee to revenue pool
     * @param _revenuePool - Revenue pool to receive rewards
     */
    constructor(
        address _admin,
        address _bot,
        address _revenuePool,
        address _stakeManager,
        uint256 _feeRate
        
    ) {
        require(
            ((_admin != address(0)) && 
            (_bot != address(0))) &&
            (_revenuePool != address(0)) &&
            (_stakeManager != address(0)),
            "Zero address provided"
        );
        require(_feeRate <= THOUSAND, "_feeRate must not exceed (100%)");

        _setRoleAdmin(BOT, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(BOT, _bot);

        feeRate = _feeRate;
        revenuePool = _revenuePool;

        emit SetRevenuePool(revenuePool);
        emit SetFeeRate(_feeRate);
    }

    /**
     * @dev StakeManager deposit ETH
     */
    function deposit() external payable override onlyETHStakeManager {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");

        // TODO 
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev StakeManager withdraw ETH
     * @param _amount - Amount of ETH for withdraw
     */
    function withdraw(uint256 _amount) external override onlyETHStakeManager {
        require(_amount > 0, "Invalid Amount");

        // TODO 

        emit Withdraw(msg.sender, _amount);
    }

    function setBotRole(address _address) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "zero address provided");

        grantRole(BOT, _address);
    }

    function revokeBotRole(address _address) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "zero address provided");

        revokeRole(BOT, _address);
    }

    function setFeeRate(uint256 _feeRate)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_feeRate <= THOUSAND, "feeRate must not exceed (100%)");

        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
    }

    function setRevenuePool(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "zero address provided");

        revenuePool = _address;
        emit SetRevenuePool(_address);
    }

    receive() external payable {
        // TODO
    }
}