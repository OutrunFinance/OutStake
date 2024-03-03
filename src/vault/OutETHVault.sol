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
    address public RETHStakeManager;
    address public revenuePool;
    uint256 public feeRate;
    FlashLoanFee public flashLoanFee;

    modifier onlyRETHContract() {
        if (msg.sender != rETH) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param _owner - Address of the owner
     * @param _rETH - Address of RETH Token
     * @param _revenuePool - Revenue pool
     * @param _feeRate - Fee to revenue pool
     * @param _feeRate - Fee to revenue pool
     */
    constructor(
        address _owner,
        address _rETH,
        address _revenuePool,
        uint256 _feeRate
    ) Ownable(_owner) {
        if (_feeRate > RATIO) {
            revert FeeRateOverflow();
        }

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
                unchecked {
                    uint256 feeAmount = yieldAmount * feeRate / RATIO;
                    Address.sendValue(payable(revenuePool), feeAmount);
                    yieldAmount -= feeAmount;
                }
            }

            IRETH(rETH).mint(RETHStakeManager, yieldAmount);
            IRETHStakeManager(RETHStakeManager).updateYieldAmount(yieldAmount);

            emit ClaimETHYield(yieldAmount);
        }
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
        receiver.transfer(amount);
        IOutFlashCallee(receiver).execute(msg.sender, amount, data);

        uint256 providerFee;
        uint256 protocolFee;
        unchecked {
            providerFee = amount * flashLoanFee.providerFeeRate / RATIO;
            protocolFee = amount * flashLoanFee.protocolFeeRate / RATIO;
            if (address(this).balance < balanceBefore + providerFee + protocolFee) {
                revert FlashLoanRepayFailed();
            }
        }
        
        IRETH(rETH).mint(RETHStakeManager, providerFee);
        Address.sendValue(payable(revenuePool), protocolFee);

        emit FlashLoan(receiver, amount);
    }

    function setFeeRate(uint256 _feeRate) external override onlyOwner {
        if (_feeRate > RATIO) {
            revert FeeRateOverflow();
        }

        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
    }

    function setFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate) external override onlyOwner {
        if (_providerFeeRate + _protocolFeeRate > RATIO) {
            revert FeeRateOverflow();
        }

        flashLoanFee = FlashLoanFee(_providerFeeRate, _protocolFeeRate);
        emit SetFlashLoanFee(_providerFeeRate, _protocolFeeRate);
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