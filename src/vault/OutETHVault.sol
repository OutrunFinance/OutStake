//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../blast/IBlastPoints.sol";
import "../blast/GasManagerable.sol";
import "../utils/Initializable.sol";
import "../stake/interfaces/IORETHStakeManager.sol";
import "../token/ETH//interfaces/IORETH.sol";
import "./interfaces/IOutETHVault.sol";
import "./interfaces/IOutFlashCallee.sol";

/**
 * @title ETH Vault Contract
 */
contract OutETHVault is IOutETHVault, ReentrancyGuard, Initializable, Ownable, GasManagerable {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO = 10000;
    uint256 public constant DAY_RATE_RATIO = 1e8;
    address public immutable BLAST_POINTS_CONFIGER;
    address public immutable ORETH;

    address private _orETHStakeManager;
    address private _revenuePool;
    uint256 private _protocolFee;
    FlashLoanFee private _flashLoanFee;

    modifier onlyORETHContract() {
        if (msg.sender != ORETH) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param owner - Address of owner
     * @param gasManager - Address of gas manager
     * @param orETH - Address of orETH Token
     * @param pointsConfiger - Address of blast points configer
     */
    constructor(address owner, address gasManager, address orETH, address pointsConfiger) Ownable(owner) GasManagerable(gasManager) {
        ORETH = orETH;
        BLAST_POINTS_CONFIGER = pointsConfiger;
    }


    /** view **/
    function ORETHStakeManager() external view returns (address) {
        return _orETHStakeManager;
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

    function setORETHStakeManager(address _stakeManager) public override onlyOwner {
        _orETHStakeManager = _stakeManager;
        emit SetORETHStakeManager(_stakeManager);
    }


    /** function **/
    /**
     * @dev Initializer
     * @param operator_ - Address of blast points operator
     * @param stakeManager_ - Address of orETHStakeManager
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
        BLAST.configureClaimableYield();
        configurePointsOperator(operator_);
        setORETHStakeManager(stakeManager_);
        setRevenuePool(revenuePool_);
        setProtocolFee(protocolFee_);
        setFlashLoanFee(providerFeeRate_, protocolFeeRate_);
    }

    /**
     * @dev When user withdraw by orETH contract
     * @param user - Address of User
     * @param amount - Amount of ETH for withdraw
     */
    function withdraw(address user, uint256 amount) external override onlyORETHContract {
        Address.sendValue(payable(user), amount);
    }

    /**
     * @dev Claim ETH yield to this contract
     */
    function claimETHYield() public override onlyOwner returns (uint256 nativeYield, uint256 dayRate) {
        nativeYield = BLAST.claimAllYield(address(this), address(this));
        if (nativeYield > 0) {
            if (_protocolFee > 0) {
                unchecked {
                    uint256 feeAmount = nativeYield * _protocolFee / RATIO;
                    Address.sendValue(payable(_revenuePool), feeAmount);
                    nativeYield -= feeAmount;
                }
            }

            IORETH(ORETH).mint(_orETHStakeManager, nativeYield);
            IORETHStakeManager(_orETHStakeManager).accumYieldPool(nativeYield);

            unchecked {
                dayRate = nativeYield * DAY_RATE_RATIO / IERC20(ORETH).balanceOf(_orETHStakeManager);
            }

            emit ClaimETHYield(nativeYield, dayRate);
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
        (bool success, ) = receiver.call{value: amount}("");
        if (success) {
            IOutFlashCallee(receiver).onFlashLoan(msg.sender, amount, data);

            uint256 providerFeeAmount;
            uint256 protocolFeeAmount;
            unchecked {
                providerFeeAmount = amount * _flashLoanFee.providerFeeRate / RATIO;
                protocolFeeAmount = amount * _flashLoanFee.protocolFeeRate / RATIO;
                if (address(this).balance < balanceBefore + providerFeeAmount + protocolFeeAmount) {
                    revert FlashLoanRepayFailed();
                }
            }
            
            IORETH(ORETH).mint(_orETHStakeManager, providerFeeAmount);
            Address.sendValue(payable(_revenuePool), protocolFeeAmount);

            emit FlashLoan(receiver, amount);
        }
    }

    function configurePointsOperator(address operator) public override onlyOwner {
        IBlastPoints(BLAST_POINTS_CONFIGER).configurePointsOperator(operator);
        emit ConfigurePointsOperator(operator);
    }

    receive() external payable {}
}