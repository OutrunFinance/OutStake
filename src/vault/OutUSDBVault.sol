//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../stake/interfaces/IRUSDStakeManager.sol";
import "../blast/IERC20Rebasing.sol";
import "./interfaces/IOutUSDBVault.sol";
import "./interfaces/IOutFlashCallee.sol";
import "../token/USDB//interfaces/IRUSD.sol";
import {BlastModeEnum} from "../blast/BlastModeEnum.sol";

/**
 * @title USDB Vault Contract
 */
contract OutUSDBVault is IOutUSDBVault, ReentrancyGuard, Ownable, BlastModeEnum {
    using SafeERC20 for IERC20;

    address public constant USDB = 0x4200000000000000000000000000000000000022;
    uint256 public constant RATIO = 10000;
    address public immutable rUSD;

    address private _RUSDStakeManager;
    address private _revenuePool;
    uint256 private _feeRate;
    FlashLoanFee private _flashLoanFee;

    modifier onlyRUSDContract() {
        if (msg.sender != rUSD) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param owner_ - Address of the owner
     * @param rUSD_ - Address of RUSD Token
     * @param revenuePool_ - Revenue pool
     * @param feeRate_ - Fee to revenue pool
     */
    constructor(
        address owner_,
        address rUSD_,
        address revenuePool_,
        uint256 feeRate_
    ) Ownable(owner_) {
        if (feeRate_ > RATIO) {
            revert FeeRateOverflow();
        }

        rUSD = rUSD_;
        _feeRate = feeRate_;
        _revenuePool = revenuePool_;

        emit SetFeeRate(feeRate_);
        emit SetRevenuePool(revenuePool_);
    }

    /** view **/
    function RUSDStakeManager() external view returns (address) {
        return _RUSDStakeManager;
    }

    function revenuePool() external view returns (address) {
        return _revenuePool;
    }

    function feeRate() external view returns (uint256) {
        return _feeRate;
    }

    function flashLoanFee() external view returns (FlashLoanFee memory) {
        return _flashLoanFee;
    }

    /** function **/
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
    function claimUSDBYield() public override returns (uint256) {
        uint256 nativeYield = IERC20Rebasing(USDB).getClaimableAmount(address(this));
        if (nativeYield > 0) {
            IERC20Rebasing(USDB).claim(address(this), nativeYield);
            if (_feeRate > 0) {
                unchecked {
                    uint256 feeAmount = nativeYield * _feeRate / RATIO;
                    IERC20(USDB).safeTransfer(_revenuePool, feeAmount);
                    nativeYield -= feeAmount;
                }
            }

            IRUSD(rUSD).mint(_RUSDStakeManager, nativeYield);
            IRUSDStakeManager(_RUSDStakeManager).updateYieldPool(nativeYield);

            emit ClaimUSDBYield(nativeYield);
        }

        return nativeYield;
    }

     /**
     * @dev Outrun USDB FlashLoan service
     * @param receiver - Address of receiver
     * @param amount - Amount of USDB loan
     * @param data - Additional data
     */
    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external override nonReentrant {
        if (amount == 0 || receiver == address(0)) {
            revert ZeroInput();
        }
        uint256 balanceBefore = IERC20(USDB).balanceOf(address(this));
        IERC20(USDB).safeTransfer(receiver, amount);
        IOutFlashCallee(receiver).execute(msg.sender, amount, data);

        uint256 providerFee;
        uint256 protocolFee;
        unchecked {
            providerFee = amount * _flashLoanFee.providerFeeRate / RATIO;
            protocolFee = amount * _flashLoanFee.protocolFeeRate / RATIO;
            if (IERC20(USDB).balanceOf(address(this)) < balanceBefore + providerFee + protocolFee) {
                revert FlashLoanRepayFailed();
            }
        }
        
        IRUSD(rUSD).mint(_RUSDStakeManager, providerFee);
        IERC20(USDB).safeTransfer(_revenuePool, protocolFee);

        emit FlashLoan(receiver, amount);
    }

    /** setter **/
    function setFeeRate(uint256 feeRate_) external override onlyOwner {
        if (feeRate_ > RATIO) {
            revert FeeRateOverflow();
        }

        _feeRate = feeRate_;
        emit SetFeeRate(feeRate_);
    }

    function setFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate) external override onlyOwner {
        if (_providerFeeRate + _protocolFeeRate > RATIO) {
            revert FeeRateOverflow();
        }

        _flashLoanFee = FlashLoanFee(_providerFeeRate, _protocolFeeRate);
        emit SetFlashLoanFee(_providerFeeRate, _protocolFeeRate);
    }

    function setRevenuePool(address _pool) external override onlyOwner {
        _revenuePool = _pool;
        emit SetRevenuePool(_pool);
    }

    function setRUSDStakeManager(address _stakeManager) external override onlyOwner {
        _RUSDStakeManager = _stakeManager;
        emit SetRUSDStakeManager(_stakeManager);
    }
}