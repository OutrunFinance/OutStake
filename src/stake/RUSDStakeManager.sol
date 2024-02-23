//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IRUSDStakeManager} from "./interfaces/IRUSDStakeManager.sol";
import {AutoIncrementId} from "../utils/AutoIncrementId.sol";
import {IRUSD} from "../token/USDB/interfaces/IRUSD.sol";
import {IPUSD} from "../token/USDB/interfaces/IPUSD.sol";
import {IRUY} from "../token/USDB/interfaces/IRUY.sol";

/**
 * @title RUSD Stake Manager Contract
 * @dev Handles Staking of RUSD
 */
contract RUSDStakeManager is IRUSDStakeManager, Ownable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    uint256 public constant MINSTAKE = 1e20;
    uint256 public constant DAY = 24 * 3600;

    address public immutable rUSD;
    address public immutable pUSD;
    address public immutable ruy;

    address public RUSDYieldPool;
    uint256 public minLockupDays;
    uint256 public maxLockupDays;

    mapping(uint256 positionId => Position) private _positions;

    /**
     * @param _owner - Address of the owner
     * @param _rUSD - Address of RUSD Token
     * @param _pUSD - Address of PUSD Token
     * @param _ruy - Address of RUY Token
     * @param _RUSDYieldPool - Address of RUSDYieldPool
     */
    constructor(
        address _owner,
        address _rUSD,
        address _pUSD,
        address _ruy,
        address _RUSDYieldPool
    ) Ownable(_owner){
        rUSD = _rUSD;
        pUSD = _pUSD;
        ruy = _ruy;
        RUSDYieldPool = _RUSDYieldPool;
    }

    function positionsOf(uint256 positionId) public view override returns (Position memory) {
        return _positions[positionId];
    }

    /**
     * @dev Allows user to deposit RUSD, then mints PUSD and RUY for the user.
     * @param amountInRUSD - RUSD staked amount, amount % 1e18 == 0
     * @param lockupDays - User can withdraw after lockupDays
     * @notice User must have approved this contract to spend RUSD
     */
    function stake(uint256 amountInRUSD, uint256 lockupDays) external override {
        require(amountInRUSD >= MINSTAKE, "Invalid Amount");
        require(
            lockupDays >= minLockupDays && lockupDays <= maxLockupDays,
            "LockupDays Invalid"
        );

        address user = msg.sender;
        uint256 amountInPUSD = CalcPUSDAmount(amountInRUSD);
        uint256 positionId = nextId();
        uint256 deadLine = block.timestamp + lockupDays * DAY;
        _positions[positionId] = Position(
            amountInRUSD,
            amountInPUSD,
            user,
            deadLine,
            false
        );

        IERC20(rUSD).safeTransferFrom(user, address(this), amountInRUSD);
        IPUSD(pUSD).mint(user, amountInPUSD);
        uint256 amountInRUY = amountInRUSD * lockupDays;
        IRUY(ruy).mint(user, amountInRUY);   

        emit StakeRUSD(user, amountInRUSD, deadLine, positionId);
    }

    /**
     * 用户销毁PUSD以将质押的RUSD取出来, 锁定时间未过期不能unstake。
     *
     * @dev Allows user to unstake funds
     * @param amountInPUSD - Amount of PUSD for burn
     * @param positionId - Staked Principal Position Id
     * @notice User must have approved this contract to spend PUSD
     */
    function unStake(uint256 amountInPUSD, uint256 positionId) external override {
        require(amountInPUSD > 0, "Invalid Amount");

        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        require(position.owner == user, "Not Owner");
        require(position.deadLine <= block.timestamp, "Lock time not expired");
        require(position.closed == false, "Position closed");
        require(position.PUSDAmount == amountInPUSD, "PUSD amount not enough");

        position.closed = true;
        _positions[positionId] = position;
        IPUSD(pUSD).burn(user, amountInPUSD);
        uint256 amountInRUSD = position.RUSDAmount;
        IERC20(rUSD).safeTransfer(user, amountInRUSD);

        emit Withdraw(msg.sender, amountInRUSD);
    }

    function getStakedRUSD() public view override returns (uint256) {
        return IRUSD(rUSD).balanceOf(address(this)) + IRUSD(rUSD).balanceOf(RUSDYieldPool);
    }

    function setRUSDYieldPool(address _pool) external onlyOwner {
        RUSDYieldPool = _pool;
        emit SetRUSDYieldPool(_pool);
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
     * @dev Calculates amount of PUSD 本金凭证算法
     */
    function CalcPUSDAmount(uint256 amountInRUSD) internal view returns (uint256) {
        uint256 totalShares = IRUSD(pUSD).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getStakedRUSD();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInRUSD * totalShares) / yieldVault;
    }

    receive() external payable {}
}