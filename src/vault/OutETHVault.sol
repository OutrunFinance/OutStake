//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../blast/IBlast.sol";
import "../utils/Initializable.sol";
import "../stake/interfaces/IRETHStakeManager.sol";
import "../token/ETH//interfaces/IRETH.sol";
import "./interfaces/IOutETHVault.sol";
import "./interfaces/IOutFlashCallee.sol";

/**
 * @title ETH Vault Contract
 */
contract OutETHVault is IOutETHVault, ReentrancyGuard, Initializable, Ownable {
    using SafeERC20 for IERC20;

    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    uint256 public constant RATIO = 10000;
    address public immutable RETH;

    address private _RETHStakeManager;
    address private _revenuePool;
    uint256 private _protocolFee;
    FlashLoanFee private _flashLoanFee;

    modifier onlyRETHContract() {
        if (msg.sender != RETH) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param owner - Address of the owner
     * @param reth - Address of RETH Token
     */
    constructor(
        address owner,
        address reth
    ) Ownable(owner) {
        RETH = reth;
    }

    /** view **/
    function RETHStakeManager() external view returns (address) {
        return _RETHStakeManager;
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

    /** function **/
    /**
     * @dev Initializer
     * @param stakeManager_ - Address of RETHStakeManager
     * @param revenuePool_ - Address of revenue pool
     * @param protocolFee_ - Protocol fee rate
     * @param providerFeeRate_ - Flashloan provider fee rate
     * @param protocolFeeRate_ - Flashloan protocol fee rate
     */
    function initialize(
        address stakeManager_, 
        address revenuePool_, 
        uint256 protocolFee_, 
        uint256 providerFeeRate_, 
        uint256 protocolFeeRate_
    ) external override initializer {
        BLAST.configureClaimableYield();
        setRETHStakeManager(stakeManager_);
        setRevenuePool(revenuePool_);
        setProtocolFee(protocolFee_);
        setFlashLoanFee(providerFeeRate_, protocolFeeRate_);
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
            if (_protocolFee > 0) {
                unchecked {
                    uint256 feeAmount = nativeYield * _protocolFee / RATIO;
                    Address.sendValue(payable(_revenuePool), feeAmount);
                    nativeYield -= feeAmount;
                }
            }

            IRETH(RETH).mint(_RETHStakeManager, nativeYield);
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

            uint256 providerFeeAmount;
            uint256 protocolFeeAmount;
            unchecked {
                providerFeeAmount = amount * _flashLoanFee.providerFeeRate / RATIO;
                protocolFeeAmount = amount * _flashLoanFee.protocolFeeRate / RATIO;
                if (address(this).balance < balanceBefore + providerFeeAmount + protocolFeeAmount) {
                    revert FlashLoanRepayFailed();
                }
            }
            
            IRETH(RETH).mint(_RETHStakeManager, providerFeeAmount);
            Address.sendValue(payable(_revenuePool), protocolFeeAmount);
            emit FlashLoan(receiver, amount);
        }
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

    function setRETHStakeManager(address _stakeManager) public override onlyOwner {
        _RETHStakeManager = _stakeManager;
        emit SetRETHStakeManager(_stakeManager);
    }

    receive() external payable {}
}