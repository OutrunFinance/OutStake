//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../blast/IERC20Rebasing.sol";
import {BlastModeEnum} from "../blast/BlastModeEnum.sol";
import {IOutUSDBVault} from "./interfaces/IOutUSDBVault.sol";
import {IRUSD} from "../token/USDB//interfaces/IRUSD.sol";

/**
 * @title USDB Vault Contract
 */
contract OutUSDBVault is IOutUSDBVault, Ownable, BlastModeEnum {
    using SafeERC20 for IERC20;

    address public constant USDB = 0x4200000000000000000000000000000000000022;
    uint256 public constant THOUSAND = 1000;

    address public immutable rUSD;
    address public revenuePool;
    address public yieldPool;
    uint256 public feeRate;

    modifier onlyRUSDContract() {
        require(msg.sender == rUSD, "Only RUSD contract");
        _;
    }

    /**
     * @param _owner - Address of the owner
     * @param _rUSD - Address of RUSD Token
     * @param _feeRate - Fee to revenue pool
     * @param _revenuePool - Revenue pool
     * @param _yieldPool - RUSD Yield pool
     */
    constructor(
        address _owner,
        address _rUSD,
        address _revenuePool,
        address _yieldPool,
        uint256 _feeRate
    ) Ownable(_owner) {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        rUSD = _rUSD;
        feeRate = _feeRate;
        revenuePool = _revenuePool;
        yieldPool = _yieldPool;

        emit SetFeeRate(_feeRate);
        emit SetRevenuePool(_revenuePool);
        emit SetYieldPool(_yieldPool);
    }

    /**
     * @dev Initialize native yield claimable
     */
    function initialize() external override {
        IERC20Rebasing(USDB).configure(YieldMode.CLAIMABLE);
    }

    /**
     * @dev When user withdraw by RUSD contract
     * @param user - Address of User
     * @param amount - Amount of USDB for withdraw
     */
    function withdraw(address user, uint256 amount) external override onlyRUSDContract {
        IERC20(USDB).safeTransfer(user, amount);
    }

    /**
     * @dev Claim USDB yield to this contract
     */
    function claimUSDBYield() public override {
        uint256 amount = IERC20Rebasing(USDB).getClaimableAmount(address(this));
        if (amount > 0) {
            IERC20Rebasing(USDB).claim(address(this), amount);
            if (feeRate > 0) {
                uint256 feeAmount = Math.mulDiv(amount, feeRate, THOUSAND);
                require(revenuePool != address(0), "revenue pool not set");
                IERC20(USDB).safeTransfer(revenuePool, feeAmount);
                amount -= feeAmount;
            }

            IRUSD(rUSD).mint(yieldPool, amount);

            emit ClaimUSDBYield(amount);
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

    function setYieldPool(address _pool) external override onlyOwner {
        yieldPool = _pool;
        emit SetYieldPool(_pool);
    }
}