//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BlastModeEnum} from "../blast/BlastModeEnum.sol";
import "../blast/IBlastPoints.sol";
import "../blast/GasManagerable.sol";
import "../blast/IERC20Rebasing.sol";
import "../stake/interfaces/IORUSDStakeManager.sol";
import "../utils/Initializable.sol";
import "../token/USDB//interfaces/IORUSD.sol";
import "./interfaces/IOutUSDBVault.sol";
import "./interfaces/IOutFlashCallee.sol";

/**
 * @title USDB Vault Contract
 */
contract OutUSDBVault is IOutUSDBVault, ReentrancyGuard, Initializable, Ownable, GasManagerable, BlastModeEnum {
    using SafeERC20 for IERC20;

    address public constant USDB = 0x4200000000000000000000000000000000000022;
    uint256 public constant RATIO = 10000;
    uint256 public constant DAY_RATE_RATIO = 1e8;
    address public immutable BLAST_POINTS_CONFIGER;
    address public immutable ORUSD;

    address private _orUSDStakeManager;
    address private _revenuePool;
    uint256 private _protocolFee;
    FlashLoanFee private _flashLoanFee;

    modifier onlyORUSDContract() {
        if (msg.sender != ORUSD) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param owner - Address of owner
     * @param gasManager - Address of gas manager
     * @param orUSD - Address of orUSD Token
     * @param pointsConfiger - Address of blast points configer
     */
    constructor(address owner, address gasManager, address orUSD, address pointsConfiger) Ownable(owner) GasManagerable(gasManager) {
        ORUSD = orUSD;
        BLAST_POINTS_CONFIGER = pointsConfiger;
    }


    /** view **/
    function ORUSDStakeManager() external view returns (address) {
        return _orUSDStakeManager;
    }

    function revenuePool() external view returns (address) {
        return _revenuePool;
    }

    function protocolFee() external view returns (uint256) {
        return _protocolFee;
    }

    function flashLoanFee() external view returns (FlashLoanFee memory) {
        return _flashLoanFee;
    }

    
    /** setter **/
    function setProtocolFee(uint256 protocolFee_) public override onlyOwner {
        if (protocolFee_ > RATIO) {
            revert FeeRateOverflow();
        }

        _protocolFee = protocolFee_;
        emit SetProtocolFee(protocolFee_);
    }

    function setFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate) public override onlyOwner {
        if (_providerFeeRate + _protocolFeeRate > RATIO) {
            revert FeeRateOverflow();
        }

        _flashLoanFee = FlashLoanFee(_providerFeeRate, _protocolFeeRate);
        emit SetFlashLoanFee(_providerFeeRate, _protocolFeeRate);
    }

    function setRevenuePool(address _pool) public override onlyOwner {
        _revenuePool = _pool;
        emit SetRevenuePool(_pool);
    }

    function setORUSDStakeManager(address _stakeManager) public override onlyOwner {
        _orUSDStakeManager = _stakeManager;
        emit SetORUSDStakeManager(_stakeManager);
    }


    /** function **/
    /**
     * @dev Initializer
     * @param operator_ - Address of blast points operator
     * @param stakeManager_ - Address of orUSDStakeManager
     * @param revenuePool_ - Address of revenue pool
     * @param protocolFee_ - Protocol fee rate
     * @param providerFeeRate_ - Flashloan provider fee rate
     * @param protocolFeeRate_ - Flashloan protocol fee rate
     */
    function initialize(
        address operator_,
        address stakeManager_, 
        address revenuePool_, 
        uint256 protocolFee_, 
        uint256 providerFeeRate_, 
        uint256 protocolFeeRate_
    ) external override initializer {
        IERC20Rebasing(USDB).configure(YieldMode.CLAIMABLE);
        configurePointsOperator(operator_);
        setORUSDStakeManager(stakeManager_);
        setRevenuePool(revenuePool_);
        setProtocolFee(protocolFee_);
        setFlashLoanFee(providerFeeRate_, protocolFeeRate_);
    }

    /**
     * @dev When user withdraw by orUSD contract
     * @param user - Address of User
     * @param amount - Amount of USDB for withdraw
     */
    function withdraw(address user, uint256 amount) external override onlyORUSDContract {
        IERC20(USDB).safeTransfer(user, amount);
    }

    /**
     * @dev Claim USDB yield to this contract
     */
    function claimUSDBYield() public override onlyOwner returns (uint256 nativeYield, uint256 dayRate) {
        nativeYield = IERC20Rebasing(USDB).getClaimableAmount(address(this));
        if (nativeYield > 0) {
            IERC20Rebasing(USDB).claim(address(this), nativeYield);
            if (_protocolFee > 0) {
                uint256 feeAmount;
                unchecked {
                    feeAmount = nativeYield * _protocolFee / RATIO;
                }
                IERC20(USDB).safeTransfer(_revenuePool, feeAmount);
                unchecked {
                    nativeYield -= feeAmount;
                }
            }

            IORUSD(ORUSD).mint(_orUSDStakeManager, nativeYield);
            IORUSDStakeManager(_orUSDStakeManager).accumYieldPool(nativeYield);

            unchecked {
                dayRate = nativeYield * DAY_RATE_RATIO / IORUSDStakeManager(_orUSDStakeManager).totalYieldPool();
            }

            emit ClaimUSDBYield(nativeYield, dayRate);
        }
    }

     /**
     * @dev Outrun USDB FlashLoan service
     * @param receiver - Address of receiver
     * @param amount - Amount of USDB loan
     * @param data - Additional data
     */
    function flashLoan(address receiver, uint256 amount, bytes calldata data) external override nonReentrant {
        if (amount == 0 || receiver == address(0)) {
            revert ZeroInput();
        }

        uint256 balanceBefore = IERC20(USDB).balanceOf(address(this));
        IERC20(USDB).safeTransfer(receiver, amount);
        IOutFlashCallee(receiver).onFlashLoan(msg.sender, amount, data);

        uint256 providerFeeAmount;
        uint256 protocolFeeAmount;
        unchecked {
            providerFeeAmount = amount * _flashLoanFee.providerFeeRate / RATIO;
            protocolFeeAmount = amount * _flashLoanFee.protocolFeeRate / RATIO;
            if (IERC20(USDB).balanceOf(address(this)) < balanceBefore + providerFeeAmount + protocolFeeAmount) {
                revert FlashLoanRepayFailed();
            }
        }
        
        IORUSD(ORUSD).mint(_orUSDStakeManager, providerFeeAmount);
        IORUSDStakeManager(_orUSDStakeManager).accumYieldPool(providerFeeAmount);
        IERC20(USDB).safeTransfer(_revenuePool, protocolFeeAmount);

        emit FlashLoan(receiver, amount);
    }

    function configurePointsOperator(address operator) public override onlyOwner {
        IBlastPoints(BLAST_POINTS_CONFIGER).configurePointsOperator(operator);
        emit ConfigurePointsOperator(operator);
    }

}