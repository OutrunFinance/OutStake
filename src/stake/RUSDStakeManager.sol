//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../utils/Math.sol";
import "../utils/Initializable.sol";
import "../utils/AutoIncrementId.sol";
import "../token/USDB/interfaces/IRUSD.sol";
import "../token/USDB/interfaces/IPUSD.sol";
import "../token/USDB/interfaces/IRUY.sol";
import "../vault/interfaces/IOutUSDBVault.sol";
import "../blast/GasManagerable.sol";
import "./interfaces/IRUSDStakeManager.sol";

/**
 * @title RUSD Stake Manager Contract
 * @dev Handles Staking of RUSD
 */
contract RUSDStakeManager is IRUSDStakeManager, Initializable, Ownable, GasManagerable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO = 10000;
    uint256 public constant MINSTAKE = 1e18;
    uint256 public constant DAY = 24 * 3600;

    address public immutable RUSD;
    address public immutable PUSD;
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
     * @param rusd - Address of RUSD Token
     * @param pusd - Address of PUSD Token
     * @param ruy - Address of RUY Token
     */
    constructor(address owner, address gasManager, address rusd, address pusd, address ruy) Ownable(owner) GasManagerable(gasManager) {
        RUSD = rusd;
        PUSD = pusd;
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

    function getStakedRUSD() public view override returns (uint256) {
        return IRUSD(RUSD).balanceOf(address(this));
    }

    function avgStakeDays() public view override returns (uint256) {
        return IERC20(RUY).totalSupply() / _totalStaked;
    }

    function calcPUSDAmount(uint256 amountInRUSD) public view override returns (uint256) {
        uint256 totalShares = IRUSD(PUSD).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 yieldVault = getStakedRUSD();
        yieldVault = yieldVault == 0 ? 1 : yieldVault;

        unchecked {
            return amountInRUSD * totalShares / yieldVault;
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
    function initialize(address outUSDBVault_, uint256 forceUnstakeFee_, uint16 minLockupDays_, uint16 maxLockupDays_)
        external
        override
        initializer
    {
        BLAST.configureClaimableGas();
        setOutUSDBVault(outUSDBVault_);
        setForceUnstakeFee(forceUnstakeFee_);
        setMinLockupDays(minLockupDays_);
        setMaxLockupDays(maxLockupDays_);
    }

    /**
     * @dev Allows user to deposit RUSD, then mints PUSD and RUY for the user.
     * @param amountInRUSD - RUSD staked amount, amount % 1e18 == 0
     * @param lockupDays - User can withdraw after lockupDays
     * @param positionOwner - Owner of position
     * @param pusdTo - Receiver of PUSD
     * @param ruyTo - Receiver of RUY
     * @notice User must have approved this contract to spend RUSD
     */
    function stake(uint256 amountInRUSD, uint16 lockupDays, address positionOwner, address pusdTo, address ruyTo)
        external
        override
        returns (uint256, uint256)
    {
        if (amountInRUSD < MINSTAKE) {
            revert MinStakeInsufficient(MINSTAKE);
        }
        if (lockupDays < _minLockupDays || lockupDays > _maxLockupDays) {
            revert InvalidLockupDays(_minLockupDays, _maxLockupDays);
        }

        address msgSender = msg.sender;
        uint256 amountInPUSD = calcPUSDAmount(amountInRUSD);
        uint256 positionId = nextId();
        uint256 amountInRUY;
        uint256 deadline;
        unchecked {
            _totalStaked += amountInRUSD;
            deadline = block.timestamp + lockupDays * DAY;
            amountInRUY = amountInRUSD * lockupDays;
        }
        _positions[positionId] =
            Position(uint96(amountInRUSD), uint96(amountInPUSD), uint56(deadline), false, positionOwner);

        IERC20(RUSD).safeTransferFrom(msgSender, address(this), amountInRUSD);
        IPUSD(PUSD).mint(pusdTo, amountInPUSD);
        IRUY(RUY).mint(ruyTo, amountInRUY);

        emit StakeRUSD(positionId, positionOwner, amountInRUSD, deadline);
        return (amountInPUSD, amountInRUY);
    }

    /**
     * @dev Allows user to unstake funds. If force unstake, need to pay force unstake fee.
     * @param positionId - Staked Principal Position Id
     */
    function unstake(uint256 positionId) external override returns (uint256) {
        address msgSender = msg.sender;
        Position storage position = _positions[positionId];
        if (position.closed) {
            revert PositionClosed();
        }
        if (position.owner != msgSender) {
            revert PermissionDenied();
        }

        position.closed = true;
        uint256 amountInRUSD = position.RUSDAmount;
        unchecked {
            _totalStaked -= amountInRUSD;
        }
        IPUSD(PUSD).burn(msgSender, position.PUSDAmount);

        uint256 deadline = position.deadline;
        uint256 currentTime = block.timestamp;
        if (deadline > currentTime) {
            uint256 amountInRUY;
            unchecked {
                amountInRUY = position.RUSDAmount * Math.ceilDiv(deadline - currentTime, DAY);
            }
            IRUY(RUY).burn(msgSender, amountInRUY);
            position.deadline = uint56(currentTime);

            uint256 fee;
            unchecked {
                fee = amountInRUSD * _forceUnstakeFee / RATIO;
                amountInRUSD -= fee;
            }
            IRUSD(RUSD).withdraw(fee);
            IERC20(RUSD).safeTransfer(IOutUSDBVault(_outUSDBVault).revenuePool(), fee);
        }
        IERC20(RUSD).safeTransfer(msgSender, amountInRUSD);

        emit Unstake(positionId, msgSender, amountInRUSD);
        return amountInRUSD;
    }

    /**
     * @dev Allows user to extend lock time
     * @param positionId - Staked Principal Position Id
     * @param extendDays - Extend lockup days
     */
    function extendLockTime(uint256 positionId, uint256 extendDays) external override returns (uint256) {
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
        position.deadline = uint56(newDeadLine);

        uint256 amountInRUY;
        unchecked {
            amountInRUY = position.RUSDAmount * extendDays;
        }
        IRUY(RUY).mint(user, amountInRUY);

        emit ExtendLockTime(positionId, extendDays, amountInRUY);
        return amountInRUY;
    }

    /**
     * @dev Allows user burn RUY to  withdraw yield
     * @param amountInRUY - Amount of RUY
     */
    function withdrawYield(uint256 amountInRUY) external override returns (uint256) {
        if (amountInRUY == 0) {
            revert ZeroInput();
        }

        IOutUSDBVault(_outUSDBVault).claimUSDBYield();
        uint256 yieldAmount;
        unchecked {
            yieldAmount = _totalYieldPool * amountInRUY / IRUY(RUY).totalSupply();
        }

        address user = msg.sender;
        IRUY(RUY).burn(user, amountInRUY);
        IERC20(RUSD).safeTransfer(user, yieldAmount);

        emit WithdrawYield(user, amountInRUY, yieldAmount);
        return yieldAmount;
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
