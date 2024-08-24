//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import "./PositionOptionsToken.sol";
import "../utils/Initializable.sol";
import "../utils/AutoIncrementId.sol";
import "../token/USDB/interfaces/IORUSD.sol";
import "../token/USDB/interfaces/IOSUSD.sol";
import "../token/USDB/interfaces/IRUY.sol";
import "../blast/GasManagerable.sol";
import "./interfaces/IORUSDStakeManager.sol";

/**
 * @title ORUSD Stake Manager Contract
 * @dev Handles Staking of orUSD
 */
contract ORUSDStakeManager is IORUSDStakeManager, PositionOptionsToken, Initializable, Ownable, GasManagerable, AutoIncrementId {
    using SafeERC20 for IERC20;

    address public constant USDB = 0x4200000000000000000000000000000000000022;
    uint256 public constant RATIO = 10000;
    uint256 public constant MINSTAKE = 1e18;
    uint256 public constant DAY = 24 * 3600;

    address public immutable ORUSD;
    address public immutable OSUSD;
    address public immutable RUY;

    uint256 private _burnedYTFee;
    uint256 private _forceUnstakeFee;
    uint256 private _totalStaked;
    uint256 private _totalYieldPool;
    uint128 private _minLockupDays;
    uint128 private _maxLockupDays;

    modifier onlyORUSDContract() {
        require(msg.sender == ORUSD, PermissionDenied());
        _;
    }

    /**
     * @param owner - Address of owner
     * @param gasManager - Address of gasManager
     * @param orUSD - Address of orUSD Token
     * @param osUSD - Address of osUSD Token
     * @param ruy - Address of RUY Token
     */
    constructor(
        address owner, 
        address gasManager, 
        address orUSD, 
        address osUSD, 
        address ruy,
        string memory uri
    ) ERC1155(uri) Ownable(owner) GasManagerable(gasManager) {
        ORUSD = orUSD;
        OSUSD = osUSD;
        RUY = ruy;
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

    function avgStakeDays() public view override returns (uint256) {
        return IERC20(RUY).totalSupply() / _totalStaked;
    }

    function calcOSUSDAmount(uint256 amountInORUSD, uint256 amountInRUY) public view override returns (uint256) {
        return amountInORUSD - (amountInRUY * _totalYieldPool / IERC20(RUY).totalSupply());
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
        require(forceUnstakeFee_ <= RATIO, FeeOverflow());

        _forceUnstakeFee = forceUnstakeFee_;
        emit SetForceUnstakeFee(forceUnstakeFee_);
    }

    /**
     * @param burnedYTFee_ - Burn more YT when force unstake
     */
    function setBurnedYTFee(uint256 burnedYTFee_) public override onlyOwner {
        require(burnedYTFee_ <= RATIO, FeeOverflow());

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
     * @dev Allows user to deposit orUSD, then mints osUSD and RUY for the user.
     * @param amountInORUSD - orUSD staked amount
     * @param lockupDays - User can withdraw after lockupDays
     * @param positionOwner - Owner of position
     * @param osUSDTo - Receiver of osUSD
     * @param ruyTo - Receiver of RUY
     * @notice User must have approved this contract to spend orUSD
     */
    function stake(
        uint128 amountInORUSD, 
        uint256 lockupDays, 
        address positionOwner, 
        address osUSDTo, 
        address ruyTo
    ) external override returns (uint256 amountInOSUSD, uint256 amountInRUY) {
        require(amountInORUSD >= MINSTAKE, MinStakeInsufficient(MINSTAKE));
        require(
            lockupDays >= _minLockupDays && lockupDays <= _maxLockupDays, 
            InvalidLockupDays(_minLockupDays, _maxLockupDays)
        );

        address msgSender = msg.sender;
        uint256 deadline;
        unchecked {
            _totalStaked += amountInORUSD;
            deadline = block.timestamp + lockupDays * DAY;
            amountInRUY = amountInORUSD * lockupDays;
        }

        IRUY(RUY).mint(ruyTo, amountInRUY);
        amountInOSUSD = calcOSUSDAmount(amountInORUSD, amountInRUY);
        uint256 positionId = _nextId();
        positions[positionId] = Position(ORUSD, amountInORUSD, uint128(amountInOSUSD), deadline);

        _mint(positionOwner, positionId, amountInORUSD, "");
        IERC20(ORUSD).safeTransferFrom(msgSender, address(this), amountInORUSD);
        IOSUSD(OSUSD).mint(osUSDTo, amountInOSUSD);

        emit StakeORUSD(positionId, amountInORUSD, amountInOSUSD, amountInRUY, deadline);
    }

    /**
     * @dev Allows user to unstake funds. If force unstake, need to pay force unstake fee.
     * @param positionId - Staked usdb position id
     * @param share - Share of the position
     */
    function unstake(uint256 positionId, uint256 share) external override {
        address msgSender = msg.sender;
        burn(msgSender, positionId, share);

        Position storage position = positions[positionId];
        uint256 stakedAmount = position.stakedAmount;
        uint256 PTAmount = position.PTAmount;
        uint256 deadline = position.deadline;
        uint256 burnedOSUSD = Math.mulDiv(PTAmount, share, stakedAmount, Math.Rounding.Ceil);
        IOSUSD(OSUSD).burn(msgSender, burnedOSUSD);
        unchecked {
            _totalStaked -= share;
        }

        uint256 burnedRUY;
        uint256 currentTime = block.timestamp;
        if (deadline > currentTime) {
            unchecked {
                burnedRUY = share * Math.ceilDiv(deadline - currentTime, DAY) * (RATIO + _burnedYTFee) / RATIO;
            }
            IRUY(RUY).burn(msgSender, burnedRUY);
            position.deadline = currentTime;

            uint256 fee;
            unchecked {
                fee = share * _forceUnstakeFee / RATIO;
                share -= fee;
            }
            IORUSD(ORUSD).withdraw(fee);
            IERC20(USDB).safeTransfer(IORUSD(ORUSD).revenuePool(), fee);
        }
        IERC20(ORUSD).safeTransfer(msgSender, share);

        emit Unstake(positionId, share, burnedOSUSD, burnedRUY);
    }

    /**
     * @dev Allows user burn RUY to withdraw yield
     * @param amountInRUY - Amount of RUY
     */
    function withdrawYield(uint256 amountInRUY) external override returns (uint256 yieldAmount) {
        require(amountInRUY != 0, ZeroInput());

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
     * @dev Handle the usdb native yield
     */
    function handleUSDBYield(
        uint256 protocolFee, 
        address revenuePool
    ) external override onlyORUSDContract returns (uint256) {
        uint256 nativeYield = IERC20(USDB).balanceOf(address(this));
        if (protocolFee > 0) {
            uint256 feeAmount;
            unchecked {
                feeAmount = nativeYield * protocolFee / RATIO;
                nativeYield -= feeAmount;
            }
            IERC20(USDB).safeTransfer(revenuePool, feeAmount);
        }

        IERC20(USDB).safeTransfer(ORUSD, nativeYield);
        unchecked {
            _totalYieldPool += nativeYield;
        }

        return nativeYield;
    }

    /**
     * @dev Accumulate the native yielde
     * @param nativeYield - Additional native yield amount
     */
    function accumYieldPool(uint256 nativeYield) external override onlyORUSDContract {
        unchecked {
            _totalYieldPool += nativeYield;
        }
    }
}
