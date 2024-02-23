//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IRETHStakeManager} from "./interfaces/IRETHStakeManager.sol";
import {AutoIncrementId} from "../utils/AutoIncrementId.sol";
import {IRETH} from "../token/ETH/interfaces/IRETH.sol";
import {IPETH} from "../token/ETH/interfaces/IPETH.sol";
import {IREY} from "../token/ETH/interfaces/IREY.sol";

/**
 * @title RETH Stake Manager Contract
 * @dev Handles Staking of RETH
 */
contract RETHStakeManager is IRETHStakeManager, Ownable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    uint256 public constant MINSTAKE = 1e16;
    uint256 public constant DAY = 24 * 3600;

    address public immutable rETH;
    address public immutable pETH;
    address public immutable rey;

    address public RETHYieldPool;
    uint256 public minLockupDays;
    uint256 public maxLockupDays;
    uint256 public reduceLockFee;

    mapping(uint256 positionId => Position) private _positions;

    /**
     * @param _owner - Address of the owner
     * @param _rETH - Address of RETH Token
     * @param _pETH - Address of PETH Token
     * @param _rey - Address of REY Token
     * @param _RETHYieldPool - Address of RETHYieldPool
     */
    constructor(
        address _owner,
        address _rETH,
        address _pETH,
        address _rey,
        address _RETHYieldPool
    ) Ownable(_owner){
        rETH = _rETH;
        pETH = _pETH;
        rey = _rey;
        RETHYieldPool = _RETHYieldPool;
    }

    function positionsOf(uint256 positionId) public view override returns (Position memory) {
        return _positions[positionId];
    }

    /**
     * @dev Allows user to deposit RETH, then mints PETH and REY for the user.
     * @param amountInRETH - RETH staked amount, amount % 1e15 == 0
     * @param lockupDays - User can withdraw after lockupDays
     * @notice User must have approved this contract to spend RETH
     */
    function stake(uint256 amountInRETH, uint256 lockupDays) external override {
        require(amountInRETH >= MINSTAKE, "Invalid amount");
        require(
            lockupDays >= minLockupDays && lockupDays <= maxLockupDays,
            "LockupDays invalid"
        );

        address user = msg.sender;
        uint256 amountInPETH = CalcPETHAmount(amountInRETH);
        uint256 positionId = nextId();
        uint256 deadLine = block.timestamp + lockupDays * DAY;
        _positions[positionId] = Position(
            amountInRETH,
            amountInPETH,
            user,
            deadLine,
            false
        );

        IERC20(rETH).safeTransferFrom(user, address(this), amountInRETH);
        IPETH(pETH).mint(user, amountInPETH);
        uint amountInREY = amountInRETH * lockupDays;
        IREY(rey).mint(user, amountInREY); 

        emit StakeRETH(positionId, user, amountInRETH, deadLine);
    }

    /**
     * @dev Allows user to unstake funds
     * @param positionId - Staked Principal Position Id
     * @notice User must have approved this contract to spend PETH
     */
    function unStake(uint256 positionId) external override {
        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        require(position.owner == user, "Not owner");
        require(position.deadLine <= block.timestamp, "Lock time not expired");
        require(position.closed == false, "Position closed");

        position.closed = true;
        _positions[positionId] = position;
        IPETH(pETH).burn(user, position.PETHAmount);
        uint256 amountInRETH = position.RETHAmount;
        IERC20(rETH).safeTransfer(user, amountInRETH);
        
        emit UnStake(positionId, msg.sender, amountInRETH);
    }

    /**
     * @dev Allows user to extend lock time
     * @param positionId - Staked Principal Position Id
     * @param extendDays - Extend lockup days
     */
    function extendLockTime(uint256 positionId, uint256 extendDays) external {
        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        require(position.owner == user, "Not owner");
        require(position.deadLine > block.timestamp, "Lock time expired");

        uint256 newDeadLine = position.deadLine + extendDays * DAY;
        uint256 intervalDaysFromNow = (newDeadLine - block.timestamp) / DAY;
        require(
            intervalDaysFromNow >= minLockupDays && intervalDaysFromNow <= maxLockupDays,
            "ExtendDays invalid"
        );

        position.deadLine = newDeadLine;
        _positions[positionId] = position;

        uint amountInREY = position.RETHAmount * extendDays;
        IREY(rey).mint(user, amountInREY);

        emit ExtendLockTime(positionId, extendDays, amountInREY);
    }

    /**
     * @dev Allows user to extend lock time
     * @param positionId - Staked Principal Position Id
     * @param reduceDays - Reduce lockup days
     * @notice User must have approved this contract to spend REY
     */
    function reduceLockTime(uint256 positionId, uint256 reduceDays) external {
        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        require(position.owner == user, "Not owner");
        uint256 newDeadLine = position.deadLine - reduceDays * DAY;
        require(newDeadLine >= block.timestamp, "Reduce too many days");

        position.deadLine = newDeadLine;
        _positions[positionId] = position;

        uint amountInREY = position.RETHAmount * reduceDays * (1 + reduceLockFee / THOUSAND);
        IREY(rey).burn(user, amountInREY);

        emit ReduceLockTime(positionId, reduceDays, amountInREY);
    }

    function getStakedRETH() public view override returns (uint256) {
        return IRETH(rETH).balanceOf(address(this)) + IRETH(rETH).balanceOf(RETHYieldPool);
    }

    function setRETHYieldPool(address _pool) external onlyOwner {
        RETHYieldPool = _pool;
        emit SetRETHYieldPool(_pool);
    }

    /**
     * @param _minLockupDays - Min lockup days
     */
    function setMinLockupDays(uint256 _minLockupDays) external onlyOwner {
        minLockupDays = _minLockupDays;
        emit SetMinLockupDays(_minLockupDays);
    }
    
    /**
     * @param _maxLockupDays - Max lockup days
     */
    function setMaxLockupDays(uint256 _maxLockupDays) external onlyOwner {
        maxLockupDays = _maxLockupDays;
        emit SetMaxLockupDays(_maxLockupDays);
    }

    /**
     * @param _reduceLockFee - Reduce lock time fee
     */
    function setReduceLockFee(uint256 _reduceLockFee) external override onlyOwner {
        require(_reduceLockFee <= THOUSAND, "ReduceLockFee must not exceed (100%)");

        reduceLockFee = _reduceLockFee;
        emit SetReduceLockFee(_reduceLockFee);
    }

    /**
     * @dev Calculates amount of PETH
     */
    function CalcPETHAmount(uint256 amountInRETH) internal view returns (uint256) {
        uint256 totalShares = IRETH(pETH).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getStakedRETH();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInRETH * totalShares) / yieldVault;
    }

    receive() external payable {}
}