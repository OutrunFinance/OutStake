//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../utils/Math.sol";
import "../utils/Initializable.sol";
import "../utils/AutoIncrementId.sol";
import "../token/USDB/interfaces/IORUSD.sol";
import "../token/USDB/interfaces/IOSUSD.sol";
import "../token/USDB/interfaces/IRUY.sol";
import "../vault/interfaces/IOutUSDBVault.sol";
import "../blast/GasManagerable.sol";
import "./interfaces/IORUSDStakeManager.sol";

/**
 * @title ORUSD Stake Manager Contract
 * @dev Handles Staking of orUSD
 */
contract ORUSDStakeManager is IORUSDStakeManager, Initializable, Ownable, GasManagerable, AutoIncrementId {
    using SafeERC20 for IERC20;

    address public constant USDB = 0x4200000000000000000000000000000000000022;
    uint256 public constant RATIO = 10000;
    uint256 public constant MINSTAKE = 1e18;
    uint256 public constant DAY = 24 * 3600;

    address public immutable ORUSD;
    address public immutable OSUSD;
    address public immutable RUY;

    address private _outUSDBVault;
    uint256 private _forceUnstakeFee;
    uint16 private _minLockupDays;
    uint16 private _maxLockupDays;
    uint256 private _totalStaked;
    uint256 private _totalYieldPool;

    mapping(uint256 positionId => Position) private _positions;

    modifier onlyOutUSDBVault() {
        if (msg.sender != _outUSDBVault) {
            revert PermissionDenied();
        }
        _;
    }

    /**
     * @param owner - Address of owner
     * @param gasManager - Address of gasManager
     * @param orUSD - Address of orUSD Token
     * @param osUSD - Address of osUSD Token
     * @param ruy - Address of RUY Token
     */
    constructor(address owner, address gasManager, address orUSD, address osUSD, address ruy) Ownable(owner) GasManagerable(gasManager) {
        ORUSD = orUSD;
        OSUSD = osUSD;
        RUY = ruy;
    }


    /** view **/
    function outUSDBVault() external view override returns (address) {
        return _outUSDBVault;
    }

    function forceUnstakeFee() external view override returns (uint256) {
        return _forceUnstakeFee;
    }

    function totalStaked() external view override returns (uint256) {
        return _totalStaked;
    }

    function totalYieldPool() external view override returns (uint256) {
        return _totalYieldPool;
    }

    function minLockupDays() external view override returns (uint16) {
        return _minLockupDays;
    }

    function maxLockupDays() external view override returns (uint16) {
        return _maxLockupDays;
    }

    function positionsOf(uint256 positionId) external view override returns (Position memory) {
        return _positions[positionId];
    }

    function avgStakeDays() public view override returns (uint256) {
        return IERC20(RUY).totalSupply() / _totalStaked;
    }

    function calcOSUSDAmount(uint256 amountInORUSD) public view override returns (uint256) {
        uint256 totalShares = IOSUSD(OSUSD).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalStaked_ = _totalStaked;
        totalStaked_ = totalStaked_ == 0 ? 1 : totalStaked_;

        unchecked {
            return amountInORUSD * totalShares / totalStaked_;
        }
    }


    /** setter **/
    /**
     * @param minLockupDays_ - Min lockup days
     */
    function setMinLockupDays(uint16 minLockupDays_) public override onlyOwner {
        _minLockupDays = minLockupDays_;
        emit SetMinLockupDays(minLockupDays_);
    }

    /**
     * @param maxLockupDays_ - Max lockup days
     */
    function setMaxLockupDays(uint16 maxLockupDays_) public override onlyOwner {
        _maxLockupDays = maxLockupDays_;
        emit SetMaxLockupDays(maxLockupDays_);
    }

    /**
     * @param forceUnstakeFee_ - Force unstake fee
     */
    function setForceUnstakeFee(uint256 forceUnstakeFee_) public override onlyOwner {
        if (forceUnstakeFee_ > RATIO) {
            revert ForceUnstakeFeeOverflow();
        }

        _forceUnstakeFee = forceUnstakeFee_;
        emit SetForceUnstakeFee(forceUnstakeFee_);
    }

    /**
     * @param outUSDBVault_ - Address of outUSDBVault
     */
    function setOutUSDBVault(address outUSDBVault_) public override onlyOwner {
        _outUSDBVault = outUSDBVault_;
        emit SetOutUSDBVault(outUSDBVault_);
    }


    /** function **/
    /**
     * @dev Initializer
     * @param outUSDBVault_ - Address of OutUSDBVault
     * @param minLockupDays_ - Min lockup days
     * @param maxLockupDays_ - Max lockup days
     * @param forceUnstakeFee_ - Force unstake fee
     */
    function initialize(
        address outUSDBVault_, 
        uint256 forceUnstakeFee_, 
        uint16 minLockupDays_, 
        uint16 maxLockupDays_
    ) external override initializer {
        setOutUSDBVault(outUSDBVault_);
        setForceUnstakeFee(forceUnstakeFee_);
        setMinLockupDays(minLockupDays_);
        setMaxLockupDays(maxLockupDays_);
    }

    /**
     * @dev Allows user to deposit orUSD, then mints osUSD and RUY for the user.
     * @param amountInORUSD - orUSD staked amount
     * @param lockupDays - User can withdraw after lockupDays
     * @param positionOwner - Owner of position
     * @param osUSDTo - Receiver of osUSD
     * @param ruyTo - Receiver of RUY
     * @notice User must have approved this contract to spend orUSD
     */
    function stake(
        uint256 amountInORUSD, 
        uint16 lockupDays, 
        address positionOwner, 
        address osUSDTo, 
        address ruyTo
    ) external override returns (uint256 amountInOSUSD, uint256 amountInRUY) {
        if (amountInORUSD < MINSTAKE) {
            revert MinStakeInsufficient(MINSTAKE);
        }
        if (lockupDays < _minLockupDays || lockupDays > _maxLockupDays) {
            revert InvalidLockupDays(_minLockupDays, _maxLockupDays);
        }

        address msgSender = msg.sender;
        amountInOSUSD = calcOSUSDAmount(amountInORUSD);
        uint256 positionId = _nextId();
        uint256 deadline;
        unchecked {
            _totalStaked += amountInORUSD;
            deadline = block.timestamp + lockupDays * DAY;
            amountInRUY = amountInORUSD * lockupDays;
        }
        _positions[positionId] =
            Position(uint104(amountInORUSD), uint104(amountInOSUSD), uint40(deadline), false, positionOwner);

        IERC20(ORUSD).safeTransferFrom(msgSender, address(this), amountInORUSD);
        IOSUSD(OSUSD).mint(osUSDTo, amountInOSUSD);
        IRUY(RUY).mint(ruyTo, amountInRUY);

        emit StakeORUSD(positionId, positionOwner, amountInORUSD, amountInOSUSD, amountInRUY, deadline);
    }

    /**
     * @dev Allows user to unstake funds. If force unstake, need to pay force unstake fee.
     * @param positionId - Staked usdb position id
     */
    function unstake(uint256 positionId) external override returns (uint256 amountInORUSD) {
        address msgSender = msg.sender;
        Position storage position = _positions[positionId];
        if (position.closed) {
            revert PositionClosed();
        }
        if (position.owner != msgSender) {
            revert PermissionDenied();
        }

        position.closed = true;
        amountInORUSD = position.orUSDAmount;
        uint256 burnedOSUSD = position.osUSDAmount;
        uint256 deadline = position.deadline;
        IOSUSD(OSUSD).burn(msgSender, burnedOSUSD);
        unchecked {
            _totalStaked -= amountInORUSD;
        }

        uint256 burnedRUY;
        uint256 currentTime = block.timestamp;
        if (deadline > currentTime) {
            unchecked {
                burnedRUY = amountInORUSD * Math.ceilDiv(deadline - currentTime, DAY);
            }
            IRUY(RUY).burn(msgSender, burnedRUY);
            position.deadline = uint40(currentTime);

            uint256 fee;
            unchecked {
                fee = amountInORUSD * _forceUnstakeFee / RATIO;
                amountInORUSD -= fee;
            }
            IORUSD(ORUSD).withdraw(fee);
            IERC20(USDB).safeTransfer(IOutUSDBVault(_outUSDBVault).revenuePool(), fee);
        }
        IERC20(ORUSD).safeTransfer(msgSender, amountInORUSD);

        emit Unstake(positionId, amountInORUSD, burnedOSUSD, burnedRUY);
    }

    /**
     * @dev Allows user to extend lock time
     * @param positionId - Staked usdb position id
     * @param extendDays - Extend lockup days
     */
    function extendLockTime(uint256 positionId, uint256 extendDays) external override returns (uint256 amountInRUY) {
        address user = msg.sender;
        Position storage position = _positions[positionId];
        if (position.owner != user) {
            revert PermissionDenied();
        }
        uint256 currentTime = block.timestamp;
        uint256 deadline = position.deadline;
        if (deadline <= currentTime) {
            revert ReachedDeadline(deadline);
        }
        uint256 newDeadLine = deadline + extendDays * DAY;
        uint256 intervalDaysFromNow = (newDeadLine - currentTime) / DAY;
        if (intervalDaysFromNow < _minLockupDays || intervalDaysFromNow > _maxLockupDays) {
            revert InvalidExtendDays();
        }
        position.deadline = uint40(newDeadLine);

        unchecked {
            amountInRUY = position.orUSDAmount * extendDays;
        }
        IRUY(RUY).mint(user, amountInRUY);

        emit ExtendLockTime(positionId, extendDays, newDeadLine, amountInRUY);
    }

    /**
     * @dev Allows user burn RUY to withdraw yield
     * @param amountInRUY - Amount of RUY
     */
    function withdrawYield(uint256 amountInRUY) external override returns (uint256 yieldAmount) {
        if (amountInRUY == 0) {
            revert ZeroInput();
        }

        unchecked {
            yieldAmount = _totalYieldPool * amountInRUY / IRUY(RUY).totalSupply();
            _totalYieldPool -= yieldAmount;
        }

        address msgSender = msg.sender;
        IRUY(RUY).burn(msgSender, amountInRUY);
        IERC20(ORUSD).safeTransfer(msgSender, yieldAmount);

        emit WithdrawYield(msgSender, amountInRUY, yieldAmount);
    }

    /**
     * @dev Accumulate the native yielde
     * @param nativeYield - Additional native yield amount
     */
    function accumYieldPool(uint256 nativeYield) external override onlyOutUSDBVault {
        unchecked {
            _totalYieldPool += nativeYield;
        }
    }
}
