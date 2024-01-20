//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IStakeManager} from "./interfaces/IStakeManager.sol";
import {IBETH} from "../lst/interfaces/IBETH.sol";
import "../utils/Pausable.sol";

/**
 * @title Stake Manager Contract
 * @dev Handles Staking of ETH
 */
contract StakeManager is IStakeManager, Pausable, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    bytes32 public constant BOT = keccak256("BOT");

    address public bETH;
    
    address private manager;
    address private proposedManager;
    address public redirectAddress;

    address public vault;

    /**
     * @param _bETH - Address of BETH Token
     * @param _manager - Address of the manager
     */
    constructor(address _bETH, address _manager) {
        _PausableInit();

        require(((_bETH != address(0)) && (_manager != address(0))), "Zero address provided");
        manager = _manager;
        bETH = _bETH;

        emit SetManager(_manager);
    }

    /**
     * @dev Allows user to deposit ETH  and mints BETH for the user
     */
    function stake() external payable override whenNotPaused {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");
        IBETH(bETH).mint(msg.sender, amount);

        // TODO Send to Vault.
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Allows user to unstake funds
     * @param _amount - Amount of ETH for withdraw
     * @notice User must have approved this contract to spend BETH
     */
    function unStake(uint256 _amount)
        external
        override
        whenNotPaused
    {
        require(_amount > 0, "Invalid Amount");

        // TODO vaultBalance
        // require(
        //     _amount <= vaultBalance,
        //     "Not enough ETH to withdraw"
        // );

        IERC20(bETH).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        emit Withdraw(msg.sender, _amount);
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

    function setRedirectAddress(address _address)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "zero address provided");

        redirectAddress = _address;
        emit SetRedirectAddress(_address);
    }

    /**
     * @dev Flips the pause state
     */
    function togglePause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        paused() ? _unpause() : _pause();
    }

    receive() external payable {
        if (msg.sender != vault && msg.sender != redirectAddress) {
            Address.sendValue(payable(redirectAddress), msg.value);
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