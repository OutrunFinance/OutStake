//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IBnUSDBVault} from "./interfaces/IBnUSDBVault.sol";
import {IBUSD} from "../token/USDB//interfaces/IBUSD.sol";

import "./IERC20Rebasing.sol";
import {MyEnumContract} from "./IERC20Enum.sol";

/**
 * @title USDB Stake Manager Contract
 * @dev Handles Staking of USDB
 */
contract BnUSDBVault is IBnUSDBVault, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    IERC20Rebasing public constant USDB = IERC20Rebasing(0x4200000000000000000000000000000000000022);


    address public immutable bUSD;
    address public bot;
    address public revenuePool;
    address public yieldPool;
    uint256 public feeRate;

    /**
     * @param _owner - Address of the owner
     * @param _bUSD - Address of BUSD Token
     * @param _bot - Address of the bot
     * @param _feeRate - Fee to revenue pool
     * @param _revenuePool - Revenue pool
     * @param _yieldPool - BUSD Yield pool
     */
    constructor(
        address _owner,
        address _bUSD,
        address _bot,
        address _revenuePool,
        address _yieldPool,
        uint256 _feeRate
    ) Ownable(_owner) {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        bUSD = _bUSD;
        feeRate = _feeRate;
        bot = _bot;
        revenuePool = _revenuePool;
        yieldPool = _yieldPool;

        BLAST.configureClaimableGas(); 
        USDB.configure(MyEnumContract.YieldMode.CLAIMABLE) 

        emit SetFeeRate(_feeRate);
        emit SetBot(_bot);
        emit SetRevenuePool(_revenuePool);
        emit SetYieldPool(_yieldPool);
    }

    /**
     * @dev Allows user to deposit USDB and mint BUSD
     */
    function deposit() public payable override {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");

        address user = msg.sender;
        IBUSD(bUSD).mint(user, amount);

        emit Deposit(user, amount);
    }

    /**
     * @dev Allows user to withdraw USDB by BUSD
     * @param amount - Amount of BUSD for burn
     */
    function withdraw(uint256 amount) external override {
        require(amount > 0, "Invalid Amount");
        address user = msg.sender;
        IBUSD(bUSD).burn(user, amount);
        Address.sendValue(payable(user), amount);

        emit Withdraw(user, amount);
    }

    /**
     * @dev Allows bot to compound rewards
     */
    function compound() external override {
        require(msg.sender == bot, "Permission denied");
        require(address(this).balance > 0, "No funds");

        // TODO 领取原生收益
        uint256 amount;
        require(USDB.getClaimableAmount(address(this))>0,"ClaimableYield is zero!");
        amount = USDB.getClaimableAmount(address(this));
        USDB.claim(address(this),amount);
        if (feeRate > 0) {
            uint256 fee = Math.mulDiv(amount, feeRate, THOUSAND);
            require(revenuePool != address(0), "revenue pool not set");
            Address.sendValue(payable(revenuePool), fee);
            amount -= fee;
        }

        IBUSD(bUSD).mint(yieldPool, amount);

        emit Compounded(amount);
    }

    function setBot(address _bot) external override onlyOwner {
        bot = _bot;
        emit SetBot(_bot);
    }

    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= THOUSAND, "FeeRate must not exceed (100%)");

        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
    }

    function setRevenuePool(address _pool) external onlyOwner {
        revenuePool = _pool;
        emit SetRevenuePool(_pool);
    }

    function setYieldPool(address _pool) external override onlyOwner {
        yieldPool = _pool;
        emit SetYieldPool(_pool);
    }

    receive() external payable {}
}