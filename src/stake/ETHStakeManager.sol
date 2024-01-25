//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    uint256 public minIntervalTime;
    address public bETH;
    address public ETHVault;

    uint256 public yieldTotalShares;
    int256 public vaultdifference;

    /**
     * @param _bETH - Address of BETH Token
     * @param _manager - Address of the manager
     */
    constructor(address _bETH, address _ETHVault, uint256 _minIntervalTime) {
        require(((_bETH != address(0)) && (_ETHVault != address(0))), "Zero address provided");
        ETHVault = _ETHVault;
        bETH = _bETH;
        minIntervalTime = _minIntervalTime;

        emit SetManager(_manager);
    }

    /**
     * 用户stake ETH，指定一个锁定时间lockTime，锁定时间前不可unstake，经过计算后铸造BETH和收益NFT
     * yieldTotalShares收益凭证总量需要累加新铸造的BETH的数量，yieldTotalShares时实际有收益的凭证
     * 数量，用户锁定时间到期后需要减去待销毁的数量，从而保证yieldTotalShares是产生收益的凭证数量，
     * 而不是BETH总发行量。相对而言vault balance也需要做出对应的变化，由于vault balance会随着时间
     * 增加，所以需要一个vault差额vaultdifference变量来辅助计算实际产生收益的balance
     * @dev Allows user to deposit ETH and mints BETH for the user
     */
    function stake(uint256 lockTime) external payable override {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");
        require(lockTime - block.timestamp >= minIntervalTime, "LockTime too short");

        // TODO Send to Vault.
        ETHVault.deposit{value: amount}();
        uint256 bETHToMint = convertToBETH(amount);
        require(bETHToMint > 0, "Invalid BETH Amount");
        IBETH(bETH).mint(msg.sender, bETHToMint);

        emit StakeETH(msg.sender, msg.value);
    }

    /**
     * @dev Allows user to unstake funds
     * @param amount - Amount of ETH for withdraw
     * @notice User must have approved this contract to spend BETH
     */
    function unStake(uint256 amount)
        external
        override
        whenNotPaused
    {
        require(amount > 0, "Invalid Amount");

        // TODO vaultBalance
        // require(
        //     _amount <= vaultBalance,
        //     "Not enough ETH to withdraw"
        // );

        IERC20(bETH).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        emit Withdraw(msg.sender, amount);
    }

    function getVaultETH() public view override returns (uint256) {
        return (amountToDelegate + totalDelegated);
    }

    /**
     * @dev Calculates amount of BETH
     */
    function convertToBETH(uint256 amountInETH)
        public
        view
        override
        returns (uint256) 
    {
        uint256 totalShares = yieldTotalShares;
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultETH() + vaultdifference;
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        uint256 amountInBETH = (amountInETH * totalShares) / yieldVault;

        return amountInBETH;
    }

    /**
     * @dev Calculates amount of ETH
     */
    function convertToETH(uint256 amountInBETH)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalShares = yieldTotalShares;
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getVaultETH() + vaultdifference;
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        uint256 amountInETH = (amountInBETH * yieldVault) / totalShares;

        return amountInETH;
    }

    function acceptNewManager() external override {
        require(
            msg.sender == proposedManager,
            "Accessible only by Proposed Manager"
        );

        manager = proposedManager;
        proposedManager = address(0);

        emit SetManager(manager);
    }

    function setRedirectAddress(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "zero address provided");

        redirectAddress = _address;
        emit SetRedirectAddress(_address);
    }

    receive() external payable {
        if (msg.sender != ETHVault && msg.sender != redirectAddress) {
            Address.sendValue(payable(redirectAddress), msg.value);
        }
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Accessible only by Manager");
        _;
    }
}