//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import {IStakeManager} from "./interfaces/IStakeManager.sol";
import {ISnBnb} from "./interfaces/ISnBnb.sol";
import {IStaking} from "./interfaces/INativeStaking.sol";

/**
 * @title Stake Manager Contract
 * @dev Handles Staking of BNB on BSC
 */
contract SnStakeManager is
    IStakeManager,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    uint256 public totalSnBnbToBurn;

    uint256 public totalDelegated; // total BNB delegated
    uint256 public amountToDelegate; // total BNB to delegate for next batch

    uint256 public nextUndelegateUUID;
    uint256 public confirmedUndelegatedUUID;

    uint256 public reserveAmount; // will be used to adjust minThreshold delegate/undelegate for natvie staking
    uint256 public totalReserveAmount;

    address private snBnb;
    address private bcValidator;

    mapping(uint256 => BotUndelegateRequest)
        private uuidToBotUndelegateRequestMap;
    mapping(address => WithdrawalRequest[]) private userWithdrawalRequests;

    uint256 public constant TEN_DECIMALS = 1e10;
    bytes32 public constant BOT = keccak256("BOT");

    address private manager;
    address private proposedManager;
    uint256 public synFee; // range {0-10_000_000_000}

    address public revenuePool;
    address public redirectAddress;

    address private constant NATIVE_STAKING = 0x0000000000000000000000000000000000002001;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param _snBnb - Address of SnBnb Token on Binance Smart Chain
     * @param _admin - Address of the admin
     * @param _manager - Address of the manager
     * @param _bot - Address of the Bot
     * @param _synFee - Rewards fee to revenue pool
     * @param _revenuePool - Revenue pool to receive rewards
     * @param _validator - Validator to delegate BNB
     */
    function initialize(
        address _snBnb,
        address _admin,
        address _manager,
        address _bot,
        uint256 _synFee,
        address _revenuePool,
        address _validator
    ) external override initializer {
        __AccessControl_init();
        __Pausable_init();

        require(
            ((_snBnb != address(0)) &&
                (_admin != address(0)) &&
                (_manager != address(0)) &&
                (_validator != address(0)) &&
                (_revenuePool != address(0)) &&
                (_bot != address(0))),
            "zero address provided"
        );
        require(_synFee <= TEN_DECIMALS, "_synFee must not exceed (100%)");

        _setRoleAdmin(BOT, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BOT, _bot);

        manager = _manager;
        snBnb = _snBnb;
        bcValidator = _validator;
        synFee = _synFee;
        revenuePool = _revenuePool;

        emit SetManager(_manager);
        emit SetBCValidator(bcValidator);
        emit SetRevenuePool(revenuePool);
        emit SetSynFee(_synFee);
    }

    /**
     * @dev Allows user to deposit Bnb at BSC and mints SnBnb for the user
     */
    function deposit() external payable override whenNotPaused {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");

        uint256 snBnbToMint = convertBnbToSnBnb(amount);
        require(snBnbToMint > 0, "Invalid SnBnb Amount");
        amountToDelegate += amount;

        ISnBnb(snBnb).mint(msg.sender, snBnbToMint);

        emit Deposit(msg.sender, msg.value);
    }

    
    /**
     * @dev Allows bot to compound rewards
     */
    function compoundRewards()
        external
        override
        whenNotPaused
        onlyRole(BOT)
    {
        require(totalDelegated > 0, "No funds delegated");

        uint256 amount = IStaking(NATIVE_STAKING).claimReward();
        
        if (synFee > 0) {
            uint256 fee = amount * synFee / TEN_DECIMALS;
            require(revenuePool != address(0x0), "revenue pool not set");
            AddressUpgradeable.sendValue(payable(revenuePool), fee);
            amount -= fee;
        }

        amountToDelegate += amount;

        emit RewardsCompounded(amount);
    }

    /**
     * @dev Allows user to request for unstake/withdraw funds
     * @param _amountInSnBnb - Amount of SnBnb to swap for withdraw
     * @notice User must have approved this contract to spend SnBnb
     */
    function requestWithdraw(uint256 _amountInSnBnb)
        external
        override
        whenNotPaused
    {
        require(_amountInSnBnb > 0, "Invalid Amount");

        totalSnBnbToBurn += _amountInSnBnb;
        uint256 totalBnbToWithdraw = convertSnBnbToBnb(totalSnBnbToBurn);
        require(
            totalBnbToWithdraw <= totalDelegated + amountToDelegate,
            "Not enough BNB to withdraw"
        );

        userWithdrawalRequests[msg.sender].push(
            WithdrawalRequest({
                uuid: nextUndelegateUUID,
                amountInSnBnb: _amountInSnBnb,
                startTime: block.timestamp
            })
        );

        IERC20Upgradeable(snBnb).safeTransferFrom(
            msg.sender,
            address(this),
            _amountInSnBnb
        );
        emit RequestWithdraw(msg.sender, _amountInSnBnb);
    }

    function claimWithdraw(uint256 _idx) external override whenNotPaused {
        address user = msg.sender;
        WithdrawalRequest[] storage userRequests = userWithdrawalRequests[user];

        require(_idx < userRequests.length, "Invalid index");

        WithdrawalRequest storage withdrawRequest = userRequests[_idx];
        uint256 uuid = withdrawRequest.uuid;
        uint256 amountInSnBnb = withdrawRequest.amountInSnBnb;

        BotUndelegateRequest
            storage botUndelegateRequest = uuidToBotUndelegateRequestMap[uuid];
        require(botUndelegateRequest.endTime != 0, "Not able to claim yet");
        userRequests[_idx] = userRequests[userRequests.length - 1];
        userRequests.pop();

        uint256 totalBnbToWithdraw_ = botUndelegateRequest.amount;
        uint256 totalSnBnbToBurn_ = botUndelegateRequest.amountInSnBnb;
        uint256 amount = (totalBnbToWithdraw_ * amountInSnBnb) /
            totalSnBnbToBurn_;

        AddressUpgradeable.sendValue(payable(user), amount);

        emit ClaimWithdrawal(user, _idx, amount);
    }


    function proposeNewManager(address _address) external override onlyManager {
        require(manager != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        proposedManager = _address;

        emit ProposeManager(_address);
    }

    function acceptNewManager() external override {
        require(
            msg.sender == proposedManager,
            "Accessible only by Proposed Manager"
        );

        manager = proposedManager;
        proposedManager = address(0);

        emit SetManager(manager);
    }

    function setBotRole(address _address) external override {
        require(_address != address(0), "zero address provided");

        grantRole(BOT, _address);

    }

    function revokeBotRole(address _address) external override {
        require(_address != address(0), "zero address provided");

        revokeRole(BOT, _address);

    }

    function setSynFee(uint256 _synFee)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_synFee <= TEN_DECIMALS, "_synFee must not exceed 10000 (100%)");

        synFee = _synFee;

        emit SetSynFee(_synFee);
    }

    function setRedirectAddress(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(redirectAddress != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        redirectAddress = _address;

        emit SetRedirectAddress(_address);
    }

    function setRevenuePool(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(revenuePool != _address, "Old address == new address");
        require(_address != address(0), "zero address provided");

        revenuePool = _address;

        emit SetRevenuePool(_address);
    }

    function getTotalPooledBnb() public view override returns (uint256) {
        return (amountToDelegate + totalDelegated);
    }

    



    /**
     * @dev Calculates amount of SnBnb for `_amount` Bnb
     */
    function convertBnbToSnBnb(uint256 _amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalShares = ISnBnb(snBnb).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledBnb = getTotalPooledBnb();
        totalPooledBnb = totalPooledBnb == 0 ? 1 : totalPooledBnb;

        uint256 amountInSnBnb = (_amount * totalShares) / totalPooledBnb;

        return amountInSnBnb;
    }

    /**
     * @dev Calculates amount of Bnb for `_amountInSnBnb` SnBnb
     */
    function convertSnBnbToBnb(uint256 _amountInSnBnb)
        public
        view
        override
        returns (uint256)
    {
        uint256 totalShares = ISnBnb(snBnb).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalPooledBnb = getTotalPooledBnb();
        totalPooledBnb = totalPooledBnb == 0 ? 1 : totalPooledBnb;

        uint256 amountInBnb = (_amountInSnBnb * totalPooledBnb) / totalShares;

        return amountInBnb;
    }

    receive() external payable {
        if (msg.sender != NATIVE_STAKING && msg.sender != redirectAddress) {
            AddressUpgradeable.sendValue(payable(redirectAddress), msg.value);
        }
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Accessible only by Manager");
        _;
    }

    modifier onlyRedirectAddress() {
        require(msg.sender == redirectAddress, "Accessible only by RedirectAddress");
        _;
    }
}