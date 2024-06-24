// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IORETH.sol";
import "../../utils/Initializable.sol";
import "../../utils/IOutFlashCallee.sol";
import "../../blast/GasManagerable.sol";
import "../../stake/interfaces/IORETHStakeManager.sol";

/**
 * @title Outrun ETH
 */
contract ORETH is IORETH, ERC20, Initializable, ReentrancyGuard, Ownable, GasManagerable {
    uint256 public constant RATIO = 10000;
    uint256 public constant DAY_RATE_RATIO = 1e8;

    address private _autoBot;
    address private _orETHStakeManager;
    address private _revenuePool;
    uint256 private _protocolFee;
    FlashLoanFee private _flashLoanFee;

    /**
     * @param owner - Address of owner
     * @param gasManager - Address of gas manager
     * @param autoBot_ - Address of autoBot
     * @param revenuePool_ - Address of revenue pool
     * @param protocolFee_ - Protocol fee rate
     * @param providerFeeRate_ - Flashloan provider fee rate
     * @param protocolFeeRate_ - Flashloan protocol fee rate
     */
    constructor(
        address owner, 
        address gasManager,
        address autoBot_,
        address revenuePool_, 
        uint256 protocolFee_, 
        uint256 providerFeeRate_, 
        uint256 protocolFeeRate_
    ) ERC20("Outrun ETH", "orETH") Ownable(owner) GasManagerable(gasManager) {
        BLAST.configureClaimableYield();
        setAutoBot(autoBot_);
        setRevenuePool(revenuePool_);
        setProtocolFee(protocolFee_);
        setFlashLoanFee(providerFeeRate_, protocolFeeRate_);
    }

    function AutoBot() external view returns (address) {
        return _autoBot;
    }

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


    function setAutoBot(address _bot) public override onlyOwner {
        _autoBot = _bot;
        emit SetAutoBot(_bot);
    }

    function setORETHStakeManager(address _stakeManager) public override onlyOwner {
        _orETHStakeManager = _stakeManager;
        emit SetORETHStakeManager(_stakeManager);
    }

    function setRevenuePool(address _pool) public override onlyOwner {
        _revenuePool = _pool;
        emit SetRevenuePool(_pool);
    }

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

    /**
     * @dev Initializer
     * @param stakeManager_ - Address of orETHStakeManager
     */
    function initialize(address stakeManager_) external override initializer {
        setORETHStakeManager(stakeManager_);
    }

    /**
     * @dev Allows user to deposit ETH and mint orETH
     */
    function deposit() public payable override {
        uint256 amount = msg.value;
        if (amount == 0) {
            revert ZeroInput();
        }

        address msgSender = msg.sender;
        _mint(msgSender, amount);

        emit Deposit(msgSender, amount);
    }

    /**
     * @dev Allows user to withdraw ETH by orETH
     * @param amount - Amount of orETH for burn
     */
    function withdraw(uint256 amount) external override {
        if (amount == 0) {
            revert ZeroInput();
        }
        address msgSender = msg.sender;
        _burn(msgSender, amount);
        Address.sendValue(payable(msgSender), amount);

        emit Withdraw(msgSender, amount);
    }

    /**
     * @dev Accumulate ETH yield
     */
    function accumETHYield() public override returns (uint256 nativeYield, uint256 dayRate) {
        if (msg.sender != _autoBot) {
            revert PermissionDenied();
        }

        nativeYield = BLAST.claimAllYield(address(this), address(this));
        if (nativeYield > 0) {
            if (_protocolFee > 0) {
                uint256 feeAmount;
                unchecked {
                    feeAmount = nativeYield * _protocolFee / RATIO;
                    nativeYield -= feeAmount;
                }

                Address.sendValue(payable(_revenuePool), feeAmount);
            }

            _mint(_orETHStakeManager, nativeYield);
            IORETHStakeManager(_orETHStakeManager).accumYieldPool(nativeYield);

            unchecked {
                dayRate = nativeYield * DAY_RATE_RATIO / IORETHStakeManager(_orETHStakeManager).totalStaked();
            }

            emit AccumETHYield(nativeYield, dayRate);
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
            
            _mint(_orETHStakeManager, providerFeeAmount);
            IORETHStakeManager(_orETHStakeManager).accumYieldPool(providerFeeAmount);
            Address.sendValue(payable(_revenuePool), protocolFeeAmount);

            emit FlashLoan(receiver, amount);
        }
    }

    receive() external payable {
        deposit();
    }
}