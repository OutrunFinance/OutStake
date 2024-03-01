//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../blast/IBlast.sol";
import "../stake/interfaces/IRETHStakeManager.sol";
import "./interfaces/IOutETHVault.sol";
import "../token/ETH//interfaces/IRETH.sol";

/**
 * @title ETH Vault Contract
 */
contract OutETHVault is IOutETHVault, Ownable {
    using SafeERC20 for IERC20;

    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    uint256 public constant THOUSAND = 1000;

    address public immutable rETH;
    address public RETHStakeManager;
    address public revenuePool;
    uint256 public feeRate;

    modifier onlyRETHContract() {
        require(msg.sender == rETH, "Only RETH contract");
        _;
    }

    /**
     * @param _owner - Address of the owner
     * @param _rETH - Address of RETH Token
     * @param _revenuePool - Revenue pool
     * @param _feeRate - Fee to revenue pool
     */
    constructor(
        address _owner,
        address _rETH,
        address _revenuePool,
        uint256 _feeRate
    ) Ownable(_owner) {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        rETH = _rETH;
        feeRate = _feeRate;
        revenuePool = _revenuePool;

        emit SetFeeRate(_feeRate);
        emit SetRevenuePool(_revenuePool);
    }

    /**
     * @dev Initialize native yield claimable
     */
    function initialize() external override {
        BLAST.configureClaimableYield();
    }

    /**
     * @dev When user withdraw by RETH contract
     * @param user - Address of User
     * @param amount - Amount of ETH for withdraw
     */
    function withdraw(address user, uint256 amount) external override onlyRETHContract {
        Address.sendValue(payable(user), amount);
    }

    /**
     * @dev Claim ETH yield to this contract
     */
    function claimETHYield() public override {
        uint256 yieldAmount = BLAST.claimAllYield(address(this), address(this));
        if (yieldAmount > 0) {
            if (feeRate > 0) {
                uint256 feeAmount = Math.mulDiv(yieldAmount, feeRate, THOUSAND);
                require(revenuePool != address(0), "revenue pool not set");
                Address.sendValue(payable(revenuePool), feeAmount);
                yieldAmount -= feeAmount;
            }

            IRETH(rETH).mint(RETHStakeManager, yieldAmount);
            IRETHStakeManager(RETHStakeManager).updateYieldAmount(yieldAmount);

            emit ClaimETHYield(yieldAmount);
        }
    }

    function setFeeRate(uint256 _feeRate) external override onlyOwner {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
    }

    function setRevenuePool(address _pool) external override onlyOwner {
        revenuePool = _pool;
        emit SetRevenuePool(_pool);
    }

    function setRETHStakeManager(address _RETHStakeManager) external override onlyOwner {
        RETHStakeManager = _RETHStakeManager;
        emit SetRETHStakeManager(_RETHStakeManager);
    }

    receive() external payable {}
}