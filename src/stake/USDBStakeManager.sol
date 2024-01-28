//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IUSDBStakeManager} from "./interfaces/IUSDBStakeManager.sol";
import {IBUSD} from "../lst/interfaces/IBUSD.sol";

/**
 * @title USDB Stake Manager Contract (Vault)
 * @dev Handles Staking of USDB
 */
contract USDBStakeManager is IUSDBStakeManager, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    bytes32 public constant BOT = keccak256("BOT");
    address public constant USDB = 0x4200000000000000000000000000000000000022;

    address public busd;
    address public revenuePool;
    uint256 public feeRate; // range {0-1000}

    /**
     * @param _admin - Address of the admin
     * @param _bot - Address of the Bot
     * @param _feeRate - Rewards fee to revenue pool
     * @param _revenuePool - Revenue pool to receive rewards
     * @param _busd - Address of BUSD Token
     */
    constructor(
        address _busd,
        address _admin,
        address _bot,
        address _revenuePool,
        uint256 _feeRate
    ) {
        require(
            (_busd != address(0)) &&
                (_admin != address(0)) &&
                (_bot != address(0)) &&
                (_revenuePool != address(0)),
            "Zero address provided"
        );
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        busd = _busd;
        feeRate = _feeRate;
        revenuePool = _revenuePool;

        _setRoleAdmin(BOT, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(BOT, _bot);

        emit SetRevenuePool(_revenuePool);
        emit SetFeeRate(_feeRate);
    }

    /**
     * 用户stake USDB，随时可以取出
     *
     * @dev Allows user to deposit USDB and mints BUSD for the user
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

        uint256 amountInUSDB = convertToUSDB(amount);
        require(amountInUSDB <= getVaultUSDB(), "Not enough USDB to withdraw");

        IBUSD(busd).burn(msg.sender, amount);
        IERC20(USDB).safeTransfer(msg.sender, amountInUSDB);

        emit UnStake(msg.sender, amount);
    }

    function getVaultUSDB() public view override returns (uint256) {
        return IERC20(USDB).balanceOf(address(this));
    }

    /**
     * @dev Calculates amount of BETH 利息凭证算法
     */
    function convertToBUSD(
        uint256 amountInUSDB
    ) public view override returns (uint256) {
        uint256 totalShares = IBUSD(busd).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultUSDB();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInUSDB * totalShares) / yieldVault;
    }

    /**
     * @dev Calculates amount of USDB
     */
    function convertToUSDB(
        uint256 amountInBUSD
    ) public view override returns (uint256) {
        uint256 totalShares = IBUSD(busd).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultUSDB();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInBUSD * yieldVault) / totalShares;
    }

    /**
     * @dev Allows bot to compound rewards
     */
    function compoundRewards() external override onlyRole(BOT) {
        require(getVaultUSDB() > 0, "No funds");

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