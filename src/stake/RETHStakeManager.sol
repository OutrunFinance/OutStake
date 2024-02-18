//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

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
    uint256 public minIntervalTime;
    uint256 public maxIntervalTime;

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

    function positionsOf(uint256 positionId) public view virtual returns (Position memory) {
        return _positions[positionId];
    }

    /**
     * 用户stake RETH，指定一个锁定到期时间deadLine，锁定到期前不可unstake，铸造相同数量的PETH和与锁定时间相关的收益代币REY
     *
     * @dev Allows user to deposit RETH, then mints PETH and REY for the user.
     * @param amountInRETH - RETH staked amount, amount % 1e15 == 0
     * @param deadLine - User can withdraw principal after deadLine
     * @notice User must have approved this contract to spend RETH
     */
    function stake(uint256 amountInRETH, uint256 deadLine) external override {
        require(amountInRETH >= MINSTAKE, "Invalid Amount");
        require(
            deadLine >= minIntervalTime + block.timestamp &&
                deadLine <= maxIntervalTime + block.timestamp,
            "LockTime Invalid"
        );

        address user = msg.sender;
        IERC20(rETH).safeTransferFrom(user, address(this), amountInRETH);
        uint256 amountInPETH = CalcPETHAmount(amountInRETH);
        IPETH(pETH).mint(user, amountInPETH);
        uint256 intervalTime = deadLine - block.timestamp;
        uint amountInREY = Math.mulDiv(amountInRETH, intervalTime, DAY);
        IREY(rey).mint(user, amountInREY);

        uint256 positionId = nextId();
        _positions[positionId] = Position(
            positionId,
            amountInRETH,
            amountInPETH,
            user,
            deadLine,
            false
        );

        emit StakeRETH(user, amountInRETH, deadLine, positionId);
    }

    /**
     * 用户销毁PETH以将质押的RETH取出来, 锁定时间未过期不能unstake。
     *
     * @dev Allows user to unstake funds
     * @param amountInPETH - Amount of PETH for burn
     * @param positionId - Staked Principal Position Id
     * @notice User must have approved this contract to spend PETH
     */
    function unStake(uint256 amountInPETH, uint256 positionId) external override {
        require(amountInPETH > 0, "Invalid Amount");

        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        require(position.owner == user, "Not Owner");
        require(position.deadLine <= block.timestamp, "Lock time not expired");
        require(position.closed == false, "Position closed");
        require(position.PETHAmount == amountInPETH, "PETH amount not enough");

        IPETH(pETH).burn(user, amountInPETH);
        uint256 amountInRETH = position.RETHAmount;
        IERC20(rETH).safeTransfer(user, amountInRETH);
        position.closed = true;
        _positions[positionId] = position;

        emit Withdraw(msg.sender, amountInRETH);
    }

    function getStakedRETH() public view override returns (uint256) {
        return IRETH(rETH).balanceOf(address(this)) + IRETH(rETH).balanceOf(RETHYieldPool);
    }

    function setRETHYieldPool(address _pool) external onlyOwner {
        RETHYieldPool = _pool;
        emit SetRETHYieldPool(_pool);
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
     * @dev Calculates amount of PETH 本金凭证算法
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