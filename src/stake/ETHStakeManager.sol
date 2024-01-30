//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IETHStakeManager} from "./interfaces/IETHStakeManager.sol";
import {IBETH} from "../lst/interfaces/IBETH.sol";

/**
 * @title ETH Stake Manager Contract
 * @dev Handles Staking of ETH
 */
contract ETHStakeManager is IETHStakeManager, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    bytes32 public constant BOT = keccak256("BOT");

    uint256 public minIntervalTime;
    address public bETH;
    address public manager;
    address public positionNFT;
    address public revenuePool;
    uint256 public feeRate; // range {0-1000}

    uint256 public yieldTotalCredential;  // 真实收益凭证总量
    uint256 public vaultdifference;
    uint256 public yieldPrincipalETH;     // 真实收益本金总量

    mapping(uint256 account => uint256 positionId) public userPositions;    // positionId = NFT tokenId

    /**
     * @param _bETH - Address of BETH Token
     * @param _admin - Address of the admin
     * @param _bot - Address of the Bot
     * @param _feeRate - Rewards fee to revenue pool
     * @param _revenuePool - Revenue pool to receive rewards
     * @param _revenuePool - Min lock interval time
     */
    constructor(
        address _bETH,
        address _admin,
        address _bot,
        address _revenuePool,
        address _positionNFT,
        uint256 _feeRate,
        uint256 _minIntervalTime
    ) {
        require(
            ((_bETH != address(0)) &&
                (_admin != address(0)) && 
                (_bot != address(0))) &&
                (_revenuePool != address(0)) &&
                (_positionNFT != address(0)),
            "Zero address provided"
        );

        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        bETH = _bETH;
        minIntervalTime = _minIntervalTime;
        feeRate = _feeRate;
        revenuePool = _revenuePool;
        positionNFT =_positionNFT;

        _setRoleAdmin(BOT, DEFAULT_ADMIN_ROLE);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(BOT, _bot);

        emit SetRevenuePool(revenuePool);
        emit SetFeeRate(_feeRate);
    }

    /**
     * 用户stake ETH，指定一个锁定时间deadLine，锁定时间前不可unstake，经过计算后铸造BETH和收益NFT
     * yieldTotalCredential收益凭证总量需要累加新铸造的BETH的数量，yieldTotalCredential表示实际有收益的凭证
     * 数量，用户锁定时间到期后结算时需要减去待销毁的数量，从而保证yieldTotalCredential是真实产生收益的凭证数量，
     * 而不是BETH总发行量。
     *
     * @dev Allows user to deposit ETH and mints BETH for the user
     */
    function stake(uint256 deadLine) external payable override {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");
        require(
            deadLine - block.timestamp >= minIntervalTime,
            "LockTime too short"
        );

        // 计算利息凭证
        uint256 bETHToMint = convertToBETH(amount);
        require(bETHToMint > 0, "Invalid BETH Amount");
        yieldTotalCredential += bETHToMint;

        // 铸造BETH
        IBETH(bETH).mint(msg.sender, bETHToMint);

        // TODO 铸造NFT证明

        emit StakeETH(msg.sender, msg.value, deadLine);
    }

    /**
     * 用户unstake,首先判断锁定时间是否已过期，否则不能unstake。
     * 然后检查NFT收益是否已经被计算并结算，如果没有，立刻手动结算。
     * 用于计算真实收益balance的yieldVault也需要减少，由于vault balance会随着时间
     * 增加，所以需要一个vault差额vaultdifference变量来辅助计算实际真实产生收益的balance
     * vault的当前balance-vaultdifference即为yieldVault
     * 最后将BETH销毁，仅将本金ETH取出来，只有作为收益证明的NFT才能将质押收益取出来。
     *
     * @dev Allows user to unstake funds
     * @param amount - Amount of BETH for burn
     * @param positionId - NFT tokenId
     * @notice User must have approved this contract to spend BETH
     */
    function unStake(uint256 amount, uint256 positionId) external override {
        require(amount > 0, "Invalid Amount");

        emit Withdraw(msg.sender, amount);
    }

    /**
     * 结算单个仓位到期收益
     * (share / totalShare) * vault - principal
     *
     * @param account - Position owner
     * @param positionId - NFT tokenId
     */
    function settlementYield(
        address account,
        uint256 positionId
    ) public override {
        
    }

    function getVaultETH() public view override returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Calculates amount of BETH 利息凭证算法
     */
    function convertToBETH(
        uint256 amountInETH
    ) public view override returns (uint256) {
        uint256 totalCredential = yieldTotalCredential;
        totalCredential = totalCredential == 0 ? 1 : totalCredential;

        uint256 yieldVault = getVaultETH() - vaultdifference;
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInETH * totalCredential) / yieldVault;
    }

    /**
     * @dev Calculates amount of ETH
     */
    function convertToETH(
        uint256 amountInBETH
    ) public view override returns (uint256) {
        uint256 totalCredential = yieldTotalCredential;
        totalCredential = totalCredential == 0 ? 1 : totalCredential;

        uint256 yieldVault = getVaultETH() - vaultdifference;
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInBETH * yieldVault) / totalCredential;
    }

    /**
     * @dev Allows bot to compound rewards
     */
    function compoundRewards() external override onlyRole(BOT) {
        require(address(this).balance > 0, "No funds");

        // TODO 领取原生收益
        uint256 amount;

        if (feeRate > 0) {
            uint256 fee = (amount * feeRate) / THOUSAND;
            require(revenuePool != address(0), "revenue pool not set");
            Address.sendValue(payable(revenuePool), fee);
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

    function setRevenuePool(
        address _address
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Zero address provided");

        revenuePool = _address;
        emit SetRevenuePool(_address);
    }

    receive() external payable {}
}