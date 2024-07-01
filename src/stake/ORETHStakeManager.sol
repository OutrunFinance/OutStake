//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../utils/Math.sol";
import "../utils/Initializable.sol";
import "../utils/AutoIncrementId.sol";
import "../token/ETH/interfaces/IREY.sol";
import "../token/ETH/interfaces/IORETH.sol";
import "../token/ETH/interfaces/IOSETH.sol";
import "../blast/GasManagerable.sol";
import "./interfaces/IORETHStakeManager.sol";

/**
 * @title ORETH Stake Manager Contract
 * @dev Handles Staking of orETH
 */
contract ORETHStakeManager is IORETHStakeManager, Initializable, Ownable, GasManagerable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO = 10000;
    uint256 public constant MINSTAKE = 1e15;
    uint256 public constant DAY = 24 * 3600;

    address public immutable ORETH;
    address public immutable OSETH;
    address public immutable REY;

    uint256 private _burnedYTFee;
    uint256 private _forceUnstakeFee;
    uint256 private _totalStaked;
    uint256 private _totalYieldPool;
    uint128 private _minLockupDays;
    uint128 private _maxLockupDays;

    mapping(uint256 positionId => Position) private _positions;

    /**
     * @param owner - Address of owner
     * @param gasManager - Address of gas manager
     * @param orETH - Address of orETH Token
     * @param osETH - Address of osETH Token
     * @param rey - Address of REY Token
     */
    constructor(address owner, address gasManager, address orETH, address osETH, address rey) Ownable(owner) GasManagerable(gasManager) {
        ORETH = orETH;
        OSETH = osETH;
        REY = rey;
    }


    /** view **/
    function forceUnstakeFee() external view override returns (uint256) {
        return _forceUnstakeFee;
    }

    function burnedYTFee() external view override returns (uint256) {
        return _burnedYTFee;
    }

    function totalStaked() external view override returns (uint256) {
        return _totalStaked;
    }

    function totalYieldPool() external view override returns (uint256) {
        return _totalYieldPool;
    }

    function minLockupDays() external view override returns (uint128) {
        return _minLockupDays;
    }

    function maxLockupDays() external view override returns (uint128) {
        return _maxLockupDays;
    }

    function positionsOf(uint256 positionId) external view override returns (Position memory) {
        return _positions[positionId];
    }

    function avgStakeDays() public view override returns (uint256) {
        return IERC20(REY).totalSupply() / _totalStaked;
    }

    function calcOSETHAmount(uint128 amountInORETH) public view override returns (uint256) {
        uint256 totalShares = IOSETH(OSETH).totalSupply();
        totalShares = totalShares == 0 ? 1 : totalShares;

        uint256 totalStaked_ = _totalStaked;
        totalStaked_ = totalStaked_ == 0 ? 1 : totalStaked_;
        
        return amountInORETH * totalShares / totalStaked_;
    }


    /** setter **/
    /**
     * @param minLockupDays_ - Min lockup days
     */
    function setMinLockupDays(uint128 minLockupDays_) public override onlyOwner {
        _minLockupDays = minLockupDays_;
        emit SetMinLockupDays(minLockupDays_);
    }

    /**
     * @param maxLockupDays_ - Max lockup days
     */
    function setMaxLockupDays(uint128 maxLockupDays_) public override onlyOwner {
        _maxLockupDays = maxLockupDays_;
        emit SetMaxLockupDays(maxLockupDays_);
    }

    /**
     * @param forceUnstakeFee_ - Force unstake fee
     */
    function setForceUnstakeFee(uint256 forceUnstakeFee_) public override onlyOwner {
        if (forceUnstakeFee_ > RATIO) {
            revert FeeOverflow();
        }

        _forceUnstakeFee = forceUnstakeFee_;
        emit SetForceUnstakeFee(forceUnstakeFee_);
    }

    /**
     * @param burnedYTFee_ - Burn more YT when force unstake
     */
    function setBurnedYTFee(uint256 burnedYTFee_) public override onlyOwner {
        if (burnedYTFee_ > RATIO) {
            revert FeeOverflow();
        }

        _burnedYTFee = burnedYTFee_;
        emit SetBurnedYTFee(burnedYTFee_);
    }

    
    /** function **/
    /**
     * @dev Initializer
     * @param forceUnstakeFee_ - Force unstake fee
     * @param burnedYTFee_ - Burn more YT when force unstake
     * @param minLockupDays_ - Min lockup days
     * @param maxLockupDays_ - Max lockup days
     */
    function initialize(
        uint256 forceUnstakeFee_, 
        uint256 burnedYTFee_,
        uint128 minLockupDays_, 
        uint128 maxLockupDays_
    ) external override initializer {
        setForceUnstakeFee(forceUnstakeFee_);
        setBurnedYTFee(burnedYTFee_);
        setMinLockupDays(minLockupDays_);
        setMaxLockupDays(maxLockupDays_);
    }

    /**
     * @dev Allows user to deposit orETH, then mints osETH and REY for the user.
     * @param amountInORETH - orETH staked amount
     * @param lockupDays - User can withdraw after lockupDays
     * @param positionOwner - Owner of position
     * @param osETHTo - Receiver of osETH
     * @param reyTo - Receiver of REY
     * @notice User must have approved this contract to spend orETH
     */
    function stake(
        uint128 amountInORETH, 
        uint256 lockupDays, 
        address positionOwner, 
        address osETHTo, 
        address reyTo
    ) external override returns (uint256 amountInOSETH, uint256 amountInREY) {
        if (amountInORETH < MINSTAKE) {
            revert MinStakeInsufficient(MINSTAKE);
        }
        if (lockupDays < _minLockupDays || lockupDays > _maxLockupDays) {
            revert InvalidLockupDays(_minLockupDays, _maxLockupDays);
        }

        address msgSender = msg.sender;
        amountInOSETH = calcOSETHAmount(amountInORETH);
        uint256 positionId = _nextId();
        uint256 deadline;
        unchecked {
            _totalStaked += amountInORETH;
            deadline = block.timestamp + lockupDays * DAY;
            amountInREY = amountInORETH * lockupDays;
        }
        _positions[positionId] = Position(positionOwner, amountInORETH, uint128(amountInOSETH), deadline, false);

        IERC20(ORETH).safeTransferFrom(msgSender, address(this), amountInORETH);
        IOSETH(OSETH).mint(osETHTo, amountInOSETH);
        IREY(REY).mint(reyTo, amountInREY);

        emit StakeORETH(positionId, positionOwner, amountInORETH, amountInOSETH, amountInREY, deadline);
    }

    /**
     * @dev Allows user to unstake funds. If force unstake, need to pay force unstake fee.
     * @param positionId - Staked ETH Position Id
     */
    function unstake(uint256 positionId) external override returns (uint256 amountInORETH) {
        address msgSender = msg.sender;
        Position storage position = _positions[positionId];
        if (position.closed) {
            revert PositionClosed();
        }
        if (position.owner != msgSender) {
            revert PermissionDenied();
        }

        position.closed = true;
        amountInORETH = position.orETHAmount;
        uint256 burnedOSETH = position.osETHAmount;
        uint256 deadline = position.deadline;
        IOSETH(OSETH).burn(msgSender, burnedOSETH);
        unchecked {
            _totalStaked -= amountInORETH;
        }
        
        uint256 burnedREY;
        uint256 currentTime = block.timestamp;
        if (deadline > currentTime) {
            unchecked {
                burnedREY = amountInORETH * Math.ceilDiv(deadline - currentTime, DAY) * (RATIO + _burnedYTFee) / RATIO;
            }
            IREY(REY).burn(msgSender, burnedREY);
            position.deadline = currentTime;

            uint256 fee;
            unchecked {
                fee = amountInORETH * _forceUnstakeFee / RATIO;
                amountInORETH -= fee;
            }
            IORETH(ORETH).withdraw(fee);
            Address.sendValue(payable(IORETH(ORETH).revenuePool()), fee);
        }        
        IERC20(ORETH).safeTransfer(msgSender, amountInORETH);

        emit Unstake(positionId, amountInORETH, burnedOSETH, burnedREY);
    }

    /**
     * @dev Allows user to extend lock time
     * @param positionId - Staked ETH Position Id
     * @param extendDays - Extend lockup days
     */
    function extendLockTime(uint256 positionId, uint256 extendDays) external override returns (uint256 amountInREY) {
        address user = msg.sender;
        Position memory position = _positions[positionId];
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
            amountInREY = position.orETHAmount * extendDays;
        }
        IREY(REY).mint(user, amountInREY);

        emit ExtendLockTime(positionId, extendDays, newDeadLine, amountInREY);
    }

    /**
     * @dev Allows user burn REY to withdraw yield
     * @param burnedREY - Amount of burned REY
     */
    function withdrawYield(uint256 burnedREY) external override returns (uint256 yieldAmount) {
        if (burnedREY == 0) {
            revert ZeroInput();
        }

        unchecked {
            yieldAmount = _totalYieldPool * burnedREY / IREY(REY).totalSupply();
            _totalYieldPool -= yieldAmount;
        }
        address msgSender = msg.sender;
        IREY(REY).burn(msgSender, burnedREY);
        IERC20(ORETH).safeTransfer(msgSender, yieldAmount);

        emit WithdrawYield(msgSender, burnedREY, yieldAmount);
    }

    /**
     * @dev Accumulate the native yield
     * @param nativeYield - Additional native yield amount
     */
    function accumYieldPool(uint256 nativeYield) external override {
        if (msg.sender != ORETH) {
            revert PermissionDenied();
        }

        unchecked {
            _totalYieldPool += nativeYield;
        }
    }

    receive() external payable {}
}
