//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRETHStakeManager.sol";
import "../vault/interfaces/IOutETHVault.sol";
import "../utils/AutoIncrementId.sol";
import "../token/ETH/interfaces/IREY.sol";
import "../token/ETH/interfaces/IRETH.sol";
import "../token/ETH/interfaces/IPETH.sol";

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

    address public outETHVault;
    uint256 public minLockupDays;
    uint256 public maxLockupDays;
    uint256 public reduceLockFee;
    uint256 public totalYieldPool;

    mapping(uint256 positionId => Position) private _positions;

    modifier onlyOutETHVault() {
        if (msg.sender != outETHVault) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param _owner - Address of the owner
     * @param _rETH - Address of RETH Token
     * @param _pETH - Address of PETH Token
     * @param _rey - Address of REY Token
     * @param _outETHVault - Address of OutETHVault
     * @param _reduceLockFee - Reduce lock time fee
     */
    constructor(
        address _owner,
        address _rETH,
        address _pETH,
        address _rey,
        address _outETHVault,
        uint256 _reduceLockFee
    ) Ownable(_owner){
        if (_reduceLockFee > THOUSAND) {
            revert ReduceLockFeeOverflow();
        }

        rETH = _rETH;
        pETH = _pETH;
        rey = _rey;
        outETHVault = _outETHVault;
        reduceLockFee = _reduceLockFee;

        emit SetOutETHVault(_outETHVault);
        emit SetReduceLockFee(_reduceLockFee);
    }

    function positionsOf(uint256 positionId) public view override returns (Position memory) {
        return _positions[positionId];
    }

    function getStakedRETH() public view override returns (uint256) {
        return IRETH(rETH).balanceOf(address(this));
    }

    /**
     * @dev Allows user to deposit RETH, then mints PETH and REY for the user.
     * @param amountInRETH - RETH staked amount, amount % 1e15 == 0
     * @param lockupDays - User can withdraw after lockupDays
     * @notice User must have approved this contract to spend RETH
     */
    function stake(uint256 amountInRETH, uint256 lockupDays) external override {
        if (amountInRETH < MINSTAKE) {
            revert MinStakeInsufficient(MINSTAKE);
        }
        if (lockupDays < minLockupDays || lockupDays > maxLockupDays) {
            revert InvalidLockupDays(minLockupDays, maxLockupDays);
        }

        address user = msg.sender;
        uint256 amountInPETH = CalcPETHAmount(amountInRETH);
        uint256 positionId = nextId();
        uint256 deadline;
        uint256 amountInREY;
        unchecked {
            deadline = block.timestamp + lockupDays * DAY;
            amountInREY = amountInRETH * lockupDays;
        }
        _positions[positionId] = Position(
            amountInRETH,
            amountInPETH,
            user,
            deadline,
            false
        );

        IERC20(rETH).safeTransferFrom(user, address(this), amountInRETH);
        IPETH(pETH).mint(user, amountInPETH);
        IREY(rey).mint(user, amountInREY); 

        emit StakeRETH(positionId, user, amountInRETH, deadline);
    }

    /**
     * @dev Allows user to unstake funds
     * @param positionId - Staked Principal Position Id
     * @notice User must have approved this contract to spend PETH
     */
    function unStake(uint256 positionId) external override {
        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        if (position.owner != user) {
            revert PermissionDenied();
        }
        if (position.deadline > block.timestamp) {
            revert NotReachedDeadline(position.deadline);
        }
        if (position.closed) {
            revert PositionClosed();
        }

        position.closed = true;
        _positions[positionId] = position;
        IPETH(pETH).burn(user, position.PETHAmount);
        uint256 amountInRETH = position.RETHAmount;
        IERC20(rETH).safeTransfer(user, amountInRETH);
        
        emit UnStake(positionId, msg.sender, amountInRETH);
    }

    /**
     * @dev Allows user burn REY to  withdraw yield
     * @param amountInREY - Amount of REY
     */
    function withdraw(uint256 amountInREY) external override {
        if (amountInREY == 0) {
            revert ZeroInput();
        }

        IOutETHVault(outETHVault).claimETHYield();
        uint256 yieldAmount;
        unchecked {
            yieldAmount = totalYieldPool * amountInREY / IREY(rey).totalSupply();
        }

        address user = msg.sender;
        IREY(rey).burn(user, amountInREY);
        IERC20(rETH).safeTransfer(user, yieldAmount);

        emit Withdraw(user, amountInREY, yieldAmount);
    }

    /**
     * @dev Allows user to extend lock time
     * @param positionId - Staked Principal Position Id
     * @param extendDays - Extend lockup days
     */
    function extendLockTime(uint256 positionId, uint256 extendDays) external {
        address user = msg.sender;
        Position memory position = positionsOf(positionId);
        if (position.owner != user) {
            revert PermissionDenied();
        }
        if (position.deadline <= block.timestamp) {
            revert ReachedDeadline(position.deadline);
        }
        uint256 newDeadLine = position.deadline + extendDays * DAY;
        uint256 intervalDaysFromNow = (newDeadLine - block.timestamp) / DAY;
        if (intervalDaysFromNow < minLockupDays || intervalDaysFromNow > maxLockupDays) {
            revert InvalidExtendDays();
        }

        position.deadline = newDeadLine;
        _positions[positionId] = position;
        uint256 amountInREY;
        unchecked {
            amountInREY = position.RETHAmount * extendDays;
        }
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
        if (position.owner != user) {
            revert PermissionDenied();
        }
        uint256 newDeadLine = position.deadline - reduceDays * DAY;
        if (newDeadLine < block.timestamp) {
            revert InvalidReduceDays();
        }

        position.deadline = newDeadLine;
        _positions[positionId] = position;

        uint256 amountInREY;
        unchecked {
            amountInREY = position.RETHAmount * reduceDays * (1 + reduceLockFee / THOUSAND);
        }
        IREY(rey).burn(user, amountInREY);

        emit ReduceLockTime(positionId, reduceDays, amountInREY);
    }

    /**
     * @param yieldAmount - Additional yield amount 
     */
    function updateYieldAmount(uint256 yieldAmount) external override onlyOutETHVault {
        unchecked {
            totalYieldPool += yieldAmount;
        }
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
        if (_reduceLockFee > THOUSAND) {
            revert ReduceLockFeeOverflow();
        }

        reduceLockFee = _reduceLockFee;
        emit SetReduceLockFee(_reduceLockFee);
    }

    /**
     * @param _outETHVault - Address of outETHVault
     */
    function setOutETHVault(address _outETHVault) external override onlyOwner {
        outETHVault = _outETHVault;
        emit SetOutETHVault(_outETHVault);
    }

    /**
     * @dev Calculates amount of PETH
     */
    function CalcPETHAmount(uint256 amountInRETH) internal view returns (uint256) {
        uint256 totalShares = IRETH(pETH).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getStakedRETH();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        unchecked {
            return amountInRETH * totalShares / yieldVault;
        }
    }

    receive() external payable {}
}
