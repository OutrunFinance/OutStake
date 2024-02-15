//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IBUSDStakeManager} from "./interfaces/IBUSDStakeManager.sol";
import {AutoIncrementId} from "../utils/AutoIncrementId.sol";
import {IBUSD} from "../token/USDB/interfaces/IBUSD.sol";
import {IPUSD} from "../token/USDB/interfaces/IPUSD.sol";
import {IBUYT} from "../token/USDB/interfaces/IBUYT.sol";

/**
 * @title BUSD Stake Manager Contract
 * @dev Handles Staking of BUSD
 */
contract BUSDStakeManager is IBUSDStakeManager, Ownable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    uint256 public constant PRECISION = 1e18;
    uint256 public constant DAY = 24 * 3600;

    address public immutable bUSD;
    address public immutable pUSD;
    address public immutable bUYT;

    address public USDBYieldPool;
    uint256 public minIntervalTime;
    uint256 public maxIntervalTime;

    mapping(uint256 positionId => Position) private _positions;

    /**
     * @param _owner - Address of the owner
     * @param _bUSD - Address of BUSD Token
     * @param _pUSD - Address of PUSD Token
     * @param _bUYT - Address of BUYT Token
     * @param _USDBYieldPool - Address of USDBYieldPool
     */
    constructor(
        address _owner,
        address _bUSD,
        address _pUSD,
        address _bUYT,
        address _USDBYieldPool
    ) Ownable(_owner){
        bUSD = _bUSD;
        pUSD = _pUSD;
        bUYT = _bUYT;
        USDBYieldPool = _USDBYieldPool;
    }

    function positionsOf(uint256 positionId) public view virtual returns (Position memory) {
        return _positions[positionId];
    }

    /**
     * @dev Allows user to deposit BUSD, then mints PUSD and BUYT for the user.
     * @param amount - BUSD staked amount, amount % 1e18 == 0
     * @param deadLine - User can withdraw principal after deadLine
     * @notice User must have approved this contract to spend BUSD
     */
    function stake(uint256 amount, uint256 deadLine) external override {
        require(amount % PRECISION == 0 && amount != 0, "Invalid Amount");
        require(
            deadLine >= minIntervalTime + block.timestamp &&
                deadLine <= maxIntervalTime + block.timestamp,
            "LockTime Invalid"
        );

        address user = msg.sender;
        IERC20(bUSD).safeTransferFrom(user, address(this), amount);
        IPUSD(pUSD).mint(user, CalcPUSDAmount(amount));
        uint256 intervalTime = deadLine - block.timestamp;
        uint amountInPUSD = Math.mulDiv(amount, intervalTime, DAY);
        IBUYT(bUYT).mint(user, amountInPUSD);

        uint256 positionId = nextId();
        _positions[positionId] = Position(
            positionId,
            amount,
            amountInPUSD,
            user,
            deadLine,
            false
        );

        emit StakeUSDB(user, amount, deadLine, positionId);
    }

    /**
     * 用户销毁PUSD以将质押的BUSD取出来, 锁定时间未过期不能unstake。
     *
     * @dev Allows user to unstake funds
     * @param amount - Amount of PUSD for burn
     * @param positionId - Staked Principal Position Id
     * @notice User must have approved this contract to spend PUSD
     */
    function unStake(uint256 amount, uint256 positionId) external override {
        require(amount > 0, "Invalid Amount");

        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        require(position.owner == user, "Not Owner");
        require(position.deadLine <= block.timestamp, "Lock time not expired");
        require(position.closed == false, "Position closed");
        require(position.PUSDAmount == amount, "PUSD amount not enough");

        IPUSD(pUSD).burn(user, amount);
        uint256 amountInBUSD = position.BUSDAmount;
        IERC20(bUSD).safeTransfer(user, amountInBUSD);
        position.closed = true;
        _positions[positionId] = position;

        emit Withdraw(msg.sender, amountInBUSD);
    }

    function getStakedBUSD() public view override returns (uint256) {
        return IBUSD(bUSD).balanceOf(address(this)) + IBUSD(bUSD).balanceOf(USDBYieldPool);
    }

    function setUSDBYieldPool(address _pool) external onlyOwner {
        USDBYieldPool = _pool;
        emit SetUSDBYieldPool(_pool);
    }

    /**
     * @param _minIntervalTime - Min lock interval time
     */
    function setMinIntervalTime(uint256 _minIntervalTime) external onlyOwner {
        minIntervalTime = _minIntervalTime;
        emit SetMinIntervalTime(_minIntervalTime);
    }
    
    /**
     * @param _maxIntervalTime - Max lock interval time
     */
    function setMaxIntervalTime(uint256 _maxIntervalTime) external onlyOwner {
        maxIntervalTime = _maxIntervalTime;
        emit SetMaxIntervalTime(_maxIntervalTime);
    }

    /**
     * @dev Calculates amount of PUSD 本金凭证算法
     */
    function CalcPUSDAmount(uint256 amountInBUSD) internal view returns (uint256) {
        uint256 totalShares = IBUSD(pUSD).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getStakedBUSD();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInBUSD * totalShares) / yieldVault;
    }

    receive() external payable {}
}