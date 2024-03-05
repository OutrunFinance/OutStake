//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRUSDStakeManager.sol";
import "../vault/interfaces/IOutUSDBVault.sol";
import "../utils/Math.sol";
import "../utils/AutoIncrementId.sol";
import "../token/USDB/interfaces/IRUSD.sol";
import "../token/USDB/interfaces/IPUSD.sol";
import "../token/USDB/interfaces/IRUY.sol";

/**
 * @title RUSD Stake Manager Contract
 * @dev Handles Staking of RUSD
 */
contract RUSDStakeManager is IRUSDStakeManager, Ownable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO = 10000;
    uint256 public constant MINSTAKE = 1e20;
    uint256 public constant DAY = 24 * 3600;

    address public immutable rUSD;
    address public immutable pUSD;
    address public immutable ruy;
    address public outUSDBVault;

    uint256 public minLockupDays;
    uint256 public maxLockupDays;
    uint256 public forceUnstakeFee;
    uint256 public totalYieldPool;
    uint256 public totalStaked;

    mapping(uint256 positionId => Position) private _positions;

    modifier onlyOutUSDBVault() {
        if (msg.sender != outUSDBVault) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param _owner - Address of the owner
     * @param _rUSD - Address of RUSD Token
     * @param _pUSD - Address of PUSD Token
     * @param _ruy - Address of RUY Token
     * @param _outUSDBVault - Address of outUSDBVault
     */
    constructor(
        address _owner,
        address _rUSD,
        address _pUSD,
        address _ruy,
        address _outUSDBVault
    ) Ownable(_owner){
        rUSD = _rUSD;
        pUSD = _pUSD;
        ruy = _ruy;
        outUSDBVault = _outUSDBVault;

        emit SetOutUSDBVault(_outUSDBVault);
    }

    function positionsOf(uint256 positionId) public view override returns (Position memory) {
        return _positions[positionId];
    }

    function getStakedRUSD() public view override returns (uint256) {
        return IRUSD(rUSD).balanceOf(address(this));
    }

    function avgStakeDays() view external override returns (uint256) {
        return IERC20(ruy).totalSupply() / totalStaked;
    }

    /**
     * @dev Allows user to deposit RUSD, then mints PUSD and RUY for the user.
     * @param amountInRUSD - RUSD staked amount, amount % 1e18 == 0
     * @param lockupDays - User can withdraw after lockupDays
     * @notice User must have approved this contract to spend RUSD
     */
    function stake(uint256 amountInRUSD, uint256 lockupDays) external override {
        if (amountInRUSD < MINSTAKE) {
            revert MinStakeInsufficient(MINSTAKE);
        }
        if (lockupDays < minLockupDays || lockupDays > maxLockupDays) {
            revert InvalidLockupDays(minLockupDays, maxLockupDays);
        }

        address user = msg.sender;
        uint256 amountInPUSD = CalcPUSDAmount(amountInRUSD);
        uint256 positionId = nextId();
        uint256 amountInRUY;
        uint256 deadline;
        unchecked {
            deadline = block.timestamp + lockupDays * DAY;
            amountInRUY = amountInRUSD * lockupDays;
        }
        _positions[positionId] = Position(
            amountInRUSD,
            amountInPUSD,
            user,
            deadline,
            false
        );

        IERC20(rUSD).safeTransferFrom(user, address(this), amountInRUSD);
        IPUSD(pUSD).mint(user, amountInPUSD);
        IRUY(ruy).mint(user, amountInRUY);   

        emit StakeRUSD(positionId, user, amountInRUSD, deadline);
    }

    /**
     * @dev Allows user to unstake funds
     * @param positionId - Staked Principal Position Id
     */
    function unstake(uint256 positionId) external override {
        Position memory position = positionsOf(positionId);

        if (position.deadline > block.timestamp) {
            revert NotReachedDeadline(position.deadline);
        }
        if (position.closed) {
            revert PositionClosed();
        }

        _unstake(positionId, position, msg.sender, false);
    }

    /**
     * @dev Allows user force unstake
     * @param positionId - Staked Principal Position Id
     */
    function forceUnstake(uint256 positionId) external {
        address msgSender = msg.sender;
        Position memory position = positionsOf(positionId);

        if (position.closed) {
            revert PositionClosed();
        }
        uint256 currentTime = block.timestamp;
        if (position.deadline <= currentTime) {
            _unstake(positionId, position, msg.sender, false);
        } else {
            uint256 amountInRUY;
            unchecked {
                amountInRUY = position.RUSDAmount * Math.ceilDiv(position.deadline - currentTime, DAY);
            }
            IRUY(ruy).burn(msgSender, amountInRUY);
            position.deadline = currentTime;
            _unstake(positionId, position, msgSender, true);
        }
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
        uint256 currentTime = block.timestamp;
        if (position.deadline <= currentTime) {
            revert ReachedDeadline(position.deadline);
        }
        uint256 newDeadLine = position.deadline + extendDays * DAY;
        uint256 intervalDaysFromNow = (newDeadLine - currentTime) / DAY;
        if (intervalDaysFromNow < minLockupDays || intervalDaysFromNow > maxLockupDays) {
            revert InvalidExtendDays();
        }

        position.deadline = newDeadLine;
        _positions[positionId] = position;
        uint256 amountInRUY;
        unchecked {
            amountInRUY = position.RUSDAmount * extendDays;
        }
        IRUY(ruy).mint(user, amountInRUY);

        emit ExtendLockTime(positionId, extendDays, amountInRUY);
    }

    /**
     * @dev Allows user burn RUY to  withdraw yield
     * @param amountInRUY - Amount of RUY
     */
    function withdrawYield(uint256 amountInRUY) external override {
        if (amountInRUY == 0) {
            revert ZeroInput();
        }

        IOutUSDBVault(outUSDBVault).claimUSDBYield();
        uint256 yieldAmount;
        unchecked {
            yieldAmount = totalYieldPool * amountInRUY / IRUY(ruy).totalSupply();
        }

        address user = msg.sender;
        IRUY(ruy).burn(user, amountInRUY);
        IERC20(rUSD).safeTransfer(user, yieldAmount);

        emit WithdrawYield(user, amountInRUY, yieldAmount);
    }

    /**
     * @param yieldAmount - Additional yield amount 
     */
    function updateYieldAmount(uint256 yieldAmount) external override onlyOutUSDBVault {
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
     * @param _forceUnstakeFee - Force unstake fee
     */
    function setForceUnstakeFee(uint256 _forceUnstakeFee) external override onlyOwner {
        if (_forceUnstakeFee > RATIO) {
            revert ForceUnstakeFeeOverflow();
        }

        forceUnstakeFee = _forceUnstakeFee;
        emit SetForceUnstakeFee(_forceUnstakeFee);
    }

    /**
     * @param _outUSDBVault - Address of outUSDBVault
     */
    function setOutUSDBVault(address _outUSDBVault) external override onlyOwner {
        outUSDBVault = _outUSDBVault;
        emit SetOutUSDBVault(_outUSDBVault);
    }

    function _unstake(uint256 positionId, Position memory position, address msgSender, bool feeOn) internal {
        if (position.owner != msgSender) {
            revert PermissionDenied();
        }

        position.closed = true;
        _positions[positionId] = position;
        IPUSD(pUSD).burn(msgSender, position.PUSDAmount);

        uint256 amountInRUSD = position.RUSDAmount;
        if (feeOn) {
            uint256 fee;
            unchecked {
                fee = amountInRUSD * forceUnstakeFee / RATIO;
                amountInRUSD -= fee;
            }
            IRUSD(rUSD).withdraw(fee);
            IERC20(rUSD).safeTransfer(IOutUSDBVault(outUSDBVault).revenuePool(), fee);
        }
        IERC20(rUSD).safeTransfer(msgSender, amountInRUSD);

        emit Unstake(positionId, msgSender, amountInRUSD);
    }
    
    /**
     * @dev Calculates amount of PUSD
     */
    function CalcPUSDAmount(uint256 amountInRUSD) internal view returns (uint256) {
        uint256 totalShares = IRUSD(pUSD).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getStakedRUSD();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        unchecked {
            return amountInRUSD * totalShares / yieldVault;
        }
    }
}
