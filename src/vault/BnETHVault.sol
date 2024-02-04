//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IBnETHVault} from "./interfaces/IBnETHVault.sol";
import {IBETH} from "../token/interfaces/IBETH.sol";

/**
 * @title ETH Stake Manager Contract
 * @dev Handles Staking of ETH
 */
contract BnETHVault is IBnETHVault, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    bytes32 public constant BOT = keccak256("BOT");

    address public immutable bETH;
    address public revenuePool;
    uint256 public feeRate;

    mapping(address account => uint256 amount) public balances;

    /**
     * @param _bETH - Address of BETH Token
     * @param _admin - Address of the admin
     * @param _bot - Address of the bot
     * @param _feeRate - Fee to revenue pool
     * @param _revenuePool - Revenue pool
     */
    constructor(
        address _bETH,
        address _admin,
        address _bot,
        address _revenuePool,
        uint256 _feeRate
    ) {
        require(
            ((_bETH != address(0)) &&
            (_admin != address(0)) &&
            (_bot != address(0)) &&
            (_revenuePool != address(0))),
            "Zero address provided"
        );

        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        bETH = _bETH;
        feeRate = _feeRate;
        revenuePool = _revenuePool;

        _setRoleAdmin(BOT, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(BOT, _bot);

        emit SetRevenuePool(revenuePool);
        emit SetFeeRate(_feeRate);
    }

    /**
     * @dev Allows user to unstake funds by BETH contract
     * @param account - Address of user
     * @param amount - Amount of BETH for burn
     */
    function withdraw(address account, uint256 amount) external override {
        require(msg.sender == bETH, "Withdraw by BETH pls");
        Address.sendValue(payable(account), amount);
    }

    /**
     * @dev Get valut ETH balance
     */
    function getVaultETH() public view override returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows bot to compound rewards
     */
    function compound() external override onlyRole(BOT) {
        require(address(this).balance > 0, "No funds");

        // TODO 领取原生收益
        uint256 amount;

        if (feeRate > 0) {
            uint256 fee = Math.mulDiv(amount, feeRate, THOUSAND);
            require(revenuePool != address(0), "revenue pool not set");
            Address.sendValue(payable(revenuePool), fee);
            amount -= fee;
        }

        // TODO 转换为BETH发送到StakeManager，StakeManager计算累计收益率

        emit Compounded(amount);
    }

    function setBotRole(
        address _address
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        grantRole(BOT, _address);
    }

    function revokeBotRole(
        address _pool
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_pool != address(0), "Zero address provided");

        revokeRole(BOT, _pool);
    }

    function setFeeRate(
        uint256 _feeRate
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
    }

    function setRevenuePool(
        address _address
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        revenuePool = _address;
        emit SetRevenuePool(_address);
    }

    receive() external payable {
        require(msg.sender == bETH, "Illegal operation");
    }
}