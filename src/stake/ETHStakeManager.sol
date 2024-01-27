//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IETHStakeManager} from "./interfaces/IETHStakeManager.sol";
import {IETHVault} from "./interfaces/IETHVault.sol";
import {IBETH} from "../lst/interfaces/IBETH.sol";

/**
 * @title ETH Stake Manager Contract
 * @dev Handles Staking of ETH
 */
contract ETHStakeManager is IETHStakeManager, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public minIntervalTime;
    address public bETH;
    address public ETHVault;
    address public manager;

    uint256 public yieldTotalShares;
    uint256 public vaultdifference;

    mapping(uint256 account => uint256 positionId) public userPositions;

    /**
     * @param _bETH - Address of BETH Token
     * @param _manager - Address of the manager
     */
    constructor(address _bETH, address _ETHVault, uint256 _minIntervalTime, address _manager) {
        require(
            ((_bETH != address(0)) && (_ETHVault != address(0)) && (_manager != address(0))),
            "Zero address provided"
        );

        ETHVault = _ETHVault;
        bETH = _bETH;
        manager = _manager;
        minIntervalTime = _minIntervalTime;

        emit SetManager(_manager);
    }

    /**
     * 用户stake ETH，指定一个锁定时间deadLine，锁定时间前不可unstake，经过计算后铸造BETH和收益NFT
     * yieldTotalShares收益凭证总量需要累加新铸造的BETH的数量，yieldTotalShares表示实际有收益的凭证
     * 数量，用户锁定时间到期后结算时需要减去待销毁的数量，从而保证yieldTotalShares是真实产生收益的凭证数量，
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

        // TODO Send to Vault.
        IETHVault(ETHVault).deposit{value: amount}();

        // 计算利息凭证
        uint256 bETHToMint = convertToBETH(amount);
        require(bETHToMint > 0, "Invalid BETH Amount");
        yieldTotalShares += bETHToMint;

        // 铸造BETH
        IBETH(bETH).mint(msg.sender, bETHToMint);

        // 铸造NFT证明

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
     * @param amount - Amount of ETH for withdraw
     * @param positionId - NFT tokenId
     * @notice User must have approved this contract to spend BETH
     */
    function unStake(uint256 amount, uint256 positionId) external override {
        require(amount > 0, "Invalid Amount");

        emit Withdraw(msg.sender, amount);
    }

    /**
     * 结算单个仓位到期收益
     * @param account - Position owner
     * @param positionId - NFT tokenId
     */
    function settlementYield(address account, uint256 positionId) public override {

    }

    function getVaultETH() public view override returns (uint256) {
        return ETHVault.balance;
    }

    /**
     * @dev Calculates amount of BETH 利息凭证算法
     */
    function convertToBETH(
        uint256 amountInETH
    ) public view override returns (uint256) {
        uint256 totalShares = yieldTotalShares;
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultETH() - vaultdifference;
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        uint256 amountInBETH = (amountInETH * totalShares) / yieldVault;

        return amountInBETH;
    }

    /**
     * @dev Calculates amount of ETH
     */
    function convertToETH(
        uint256 amountInBETH
    ) public view override returns (uint256) {
        uint256 totalShares = yieldTotalShares;
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultETH() - vaultdifference;
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        uint256 amountInETH = (amountInBETH * yieldVault) / totalShares;

        return amountInETH;
    }

    function setManager(address _manager) external override {
        require(_manager != address(0), "Zero address provided");

        manager = _manager;
        emit SetManager(_manager);
    }

    receive() external payable {

    }

    modifier onlyManager() {
        require(msg.sender == manager, "Accessible only by Manager");
        _;
    }
}
