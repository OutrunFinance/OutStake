//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IBUSDStakeManager} from "./interfaces/IBUSDStakeManager.sol";
import {IBUSD} from "../token/USDB/interfaces/IBUSD.sol";
import {IPUSD} from "../token/USDB/interfaces/IPUSD.sol";

/**
 * @title BUSD Stake Manager Contract
 * @dev Handles Staking of BUSD
 */
contract BUSDStakeManager is IBUSDStakeManager, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    bytes32 public constant BOT = keccak256("BOT");
    address public constant USDB = 0x4200000000000000000000000000000000000022;

    address public busd;
    address public pusd;
    address public revenuePool;
    uint256 public feeRate; // range {0-1000}

    /**
     * @param _admin - Address of the admin
     * @param _bot - Address of the Bot
     * @param _busd - Address of BUSD Token
     * @param _pusd - Address of PUSD Token
     * @param _feeRate - Rewards fee to revenue pool
     * @param _revenuePool - Revenue pool to receive rewards
     */
    constructor(
        address _admin,
        address _busd,
        address _pusd,
        address _bot,
        address _revenuePool,
        uint256 _feeRate
    ) {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        busd = _busd;
        pusd = _pusd;
        feeRate = _feeRate;
        revenuePool = _revenuePool;

        _setRoleAdmin(BOT, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(BOT, _bot);

        emit SetRevenuePool(_revenuePool);
        emit SetFeeRate(_feeRate);
    }

    /**
     * 用户stake BUSD
     *
     * @dev Allows user to deposit BUSD and mints PUSD for the user
     */
    function stake(uint256 amount) external payable override {
        require(amount > 0, "Invalid Amount");

        uint256 busdToMint = convertToBUSD(amount);
        require(busdToMint > 0, "Invalid BUSD Amount");

        IERC20(USDB).safeTransferFrom(msg.sender, address(this), amount);
        IBUSD(busd).mint(msg.sender, busdToMint);
        
        emit Stake(msg.sender, amount);
    }

    /**
     * @dev Allows user to unstake funds
     * @param amount - Amount of BUSD for burn
     * @notice User must have approved this contract to spend BUSD
     */
    function unStake(uint256 amount) external override {
        require(amount > 0, "Invalid Amount");

        emit UnStake(msg.sender, amount);
    }

    function getVaultBUSD() public view override returns (uint256) {
        return IERC20(USDB).balanceOf(address(this));
    }

    /**
     * @dev Calculates amount of PUSD 本金凭证算法
     */
    function convertToPUSD(
        uint256 amountInBUSD
    ) public view override returns (uint256) {
        uint256 totalShares = IPUSD(pusd).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultBUSD();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInBUSD * totalShares) / yieldVault;
    }

    /**
     * @dev Calculates amount of BUSD
     */
    function convertToBUSD(
        uint256 amountInPUSD
    ) public view override returns (uint256) {
        uint256 totalShares = IPUSD(pusd).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultBUSD();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInPUSD * yieldVault) / totalShares;
    }

    /**
     * @dev Allows bot to compound rewards
     */
    function compoundRewards() external override onlyRole(BOT) {
        require(getVaultBUSD() > 0, "No funds");

        // TODO 领取原生收益
        uint256 amount;

        if (feeRate > 0) {
            uint256 fee = (amount * feeRate) / THOUSAND;
            require(revenuePool != address(0), "revenue pool not set");
            IERC20(USDB).safeTransfer(revenuePool, fee);
            amount -= fee;
        }

        emit RewardsCompounded(amount);
    }

    function setBotRole(
        address _address
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        grantRole(BOT, _address);
    }

    function revokeBotRole(
        address _address
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        revokeRole(BOT, _address);
    }

    function setFeeRate(
        uint256 _feeRate
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
    }

    /**
     * Set DAO revenue pool
     */
    function setRevenuePool(
        address _address
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        revenuePool = _address;
        emit SetRevenuePool(_address);
    }
}