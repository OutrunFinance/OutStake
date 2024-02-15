//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IBETHStakeManager} from "./interfaces/IBETHStakeManager.sol";
import {AutoIncrementId} from "../utils/AutoIncrementId.sol";
import {IBETH} from "../token/ETH/interfaces/IBETH.sol";
import {IPETH} from "../token/ETH/interfaces/IPETH.sol";
import {IBEYT} from "../token/ETH/interfaces/IBEYT.sol";

/**
 * @title BETH Stake Manager Contract
 * @dev Handles Staking of BETH
 */
contract BETHStakeManager is IBETHStakeManager, Ownable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    uint256 public constant PRECISION = 1e15;
    uint256 public constant DAY = 24 * 3600;

    address public immutable bETH;
    address public immutable pETH;
    address public immutable bEYT;

    address public BETHYieldPool;
    uint256 public minIntervalTime;
    uint256 public maxIntervalTime;

    mapping(uint256 positionId => Position) private _positions;

    /**
     * @param _owner - Address of the owner
     * @param _bETH - Address of BETH Token
     * @param _pETH - Address of PETH Token
     * @param _bEYT - Address of BEYT Token
     * @param _BETHYieldPool - Address of BETHYieldPool
     */
    constructor(
        address _owner,
        address _bETH,
        address _pETH,
        address _bEYT,
        address _BETHYieldPool
    ) Ownable(_owner){
        bETH = _bETH;
        pETH = _pETH;
        bEYT = _bEYT;
        BETHYieldPool = _BETHYieldPool;
    }

    function positionsOf(uint256 positionId) public view virtual returns (Position memory) {
        return _positions[positionId];
    }

    /**
     * 用户stake BETH，指定一个锁定到期时间deadLine，锁定到期前不可unstake，铸造相同数量的PETH和与锁定时间相关的收益代币BEYT
     *
     * @dev Allows user to deposit BETH, then mints PETH and BEYT for the user.
     * @param amount - BETH staked amount, amount % 1e15 == 0
     * @param deadLine - User can withdraw principal after deadLine
     * @notice User must have approved this contract to spend BETH
     */
    function stake(uint256 amount, uint256 deadLine) external override {
        require(amount % PRECISION == 0 && amount != 0, "Invalid Amount");
        require(
            deadLine >= minIntervalTime + block.timestamp &&
                deadLine <= maxIntervalTime + block.timestamp,
            "LockTime Invalid"
        );

        address user = msg.sender;
        IERC20(bETH).safeTransferFrom(user, address(this), amount);
        IPETH(pETH).mint(user, CalcPETHAmount(amount));
        uint256 intervalTime = deadLine - block.timestamp;
        uint amountInPETH = Math.mulDiv(amount, intervalTime, DAY);
        IBEYT(bEYT).mint(user, amountInPETH);

        uint256 positionId = nextId();
        _positions[positionId] = Position(
            positionId,
            amount,
            amountInPETH,
            user,
            deadLine,
            false
        );

        emit StakeBETH(user, amount, deadLine, positionId);
    }

    /**
     * 用户销毁PETH以将质押的BETH取出来, 锁定时间未过期不能unstake。
     *
     * @dev Allows user to unstake funds
     * @param amount - Amount of PETH for burn
     * @param positionId - Staked Principal Position Id
     * @notice User must have approved this contract to spend PETH
     */
    function unStake(uint256 amount, uint256 positionId) external override {
        require(amount > 0, "Invalid Amount");

        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        require(position.owner == user, "Not Owner");
        require(position.deadLine <= block.timestamp, "Lock time not expired");
        require(position.closed == false, "Position closed");
        require(position.PETHAmount == amount, "PETH amount not enough");

        IPETH(pETH).burn(user, amount);
        uint256 amountInBETH = position.BETHAmount;
        IERC20(bETH).safeTransfer(user, amountInBETH);
        position.closed = true;
        _positions[positionId] = position;

        emit Withdraw(msg.sender, amountInBETH);
    }

    function getStakedBETH() public view override returns (uint256) {
        return IBETH(bETH).balanceOf(address(this)) + IBETH(bETH).balanceOf(BETHYieldPool);
    }

    function setBETHYieldPool(address _pool) external onlyOwner {
        BETHYieldPool = _pool;
        emit SetBETHYieldPool(_pool);
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
    function CalcPETHAmount(uint256 amountInBETH) internal view returns (uint256) {
        uint256 totalShares = IBETH(pETH).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getStakedBETH();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        return (amountInBETH * totalShares) / yieldVault;
    }

    receive() external payable {}
}