//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../blast/IBlast.sol";
import "../stake/interfaces/IRETHStakeManager.sol";
import "./interfaces/IOutETHVault.sol";
import "./interfaces/IOutFlashCallee.sol";
import "../token/ETH//interfaces/IRETH.sol";

/**
 * @title ETH Vault Contract
 */
contract OutETHVault is IOutETHVault, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    uint256 public constant RATIO = 10000;
    address public immutable rETH;

    address private _RETHStakeManager;
    address private _revenuePool;
    uint256 private _feeRate;
    FlashLoanFee private _flashLoanFee;

    modifier onlyRETHContract() {
        if (msg.sender != rETH) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param owner_ - Address of the owner
     * @param rETH_ - Address of RETH Token
     * @param revenuePool_ - Revenue pool
     * @param feeRate_ - FeeRate to revenue pool
     */
    constructor(
        address owner_,
        address rETH_,
        address revenuePool_,
        uint256 feeRate_
    ) Ownable(owner_) {
        if (feeRate_ > RATIO) {
            revert FeeRateOverflow();
        }

        rETH = rETH_;
        _feeRate = feeRate_;
        _revenuePool = revenuePool_;

        emit SetFeeRate(feeRate_);
        emit SetRevenuePool(revenuePool_);
    }

    /** view **/
    function RETHStakeManager() external view returns (address) {
        return _RETHStakeManager;
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
    function claimETHYield() public override returns (uint256) {
        uint256 nativeYield = BLAST.claimAllYield(address(this), address(this));
        if (nativeYield > 0) {
            if (_feeRate > 0) {
                unchecked {
                    uint256 feeAmount = nativeYield * _feeRate / RATIO;
                    Address.sendValue(payable(_revenuePool), feeAmount);
                    nativeYield -= feeAmount;
                }
            }

            IRETH(rETH).mint(_RETHStakeManager, nativeYield);
            IRETHStakeManager(_RETHStakeManager).updateYieldPool(nativeYield);
        }

        emit ClaimETHYield(nativeYield);
        return nativeYield;
    }

    /**
     * @dev Outrun ETH FlashLoan service
     * @param receiver - Address of receiver
     * @param amount - Amount of ETH loan
     * @param data - Additional data
     */
    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external override nonReentrant {
        if (amount == 0 || receiver == address(0)) {
            revert ZeroInput();
        }

        uint256 balanceBefore = address(this).balance;
        (bool success, ) = receiver.call{value: amount}("");
        if (success) {
            IOutFlashCallee(receiver).execute(msg.sender, amount, data);

            uint256 providerFee;
            uint256 protocolFee;
            unchecked {
                providerFee = amount * _flashLoanFee.providerFeeRate / RATIO;
                protocolFee = amount * _flashLoanFee.protocolFeeRate / RATIO;
                if (address(this).balance < balanceBefore + providerFee + protocolFee) {
                    revert FlashLoanRepayFailed();
                }
            }
            
            IRETH(rETH).mint(_RETHStakeManager, providerFee);
            Address.sendValue(payable(_revenuePool), protocolFee);
            emit FlashLoan(receiver, amount);
        }
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

    function setRETHStakeManager(address _stakeManager) external override onlyOwner {
        _RETHStakeManager = _stakeManager;
        emit SetRETHStakeManager(_stakeManager);
    }

    receive() external payable {}
}