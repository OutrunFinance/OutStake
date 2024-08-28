//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import "../../utils/Initializable.sol";
import "../../utils/AutoIncrementId.sol";
import "../../utils/IOutFlashCallee.sol";
import "../common/PositionOptionsToken.sol";
import "../../external/lista/IStakeManager.sol";
import "../../external/chainlink/AggregatorV3Interface.sol";
import "../../token/stone/interfaces/IOSTONE.sol";
import "../../token/stone/interfaces/IYSTONE.sol";
import "../interfaces/INativeYieldTokenStakeManager.sol";

/**
 * @title Stone ETH Stake Manager Contract
 * @dev Handles Staking of STONE
 */
contract StoneETHStakeManager is INativeYieldTokenStakeManager, PositionOptionsToken, Initializable, ReentrancyGuard, Ownable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO = 10000;
    uint256 public constant MINSTAKE = 1e16;
    uint256 public constant DAY = 24 * 3600;

    address public immutable STONE;
    address public immutable PT_STONE;
    address public immutable YT_STONE;
    address public immutable STONE_ETH_DATA_FEED;

    address private _revenuePool;
    uint256 private _totalStaked;
    uint256 private _yieldPool;
    uint256 private _totalPrincipalValue;
    uint256 private _protocolFeeRate;
    uint256 private _burnedYTFeeRate;
    uint256 private _forceUnstakeFeeRate;
    uint128 private _minLockupDays;
    uint128 private _maxLockupDays;
    FlashLoanFeeRate private _flashLoanFeeRate;

    /**
     * @param owner - Address of owner
     * @param stone - Address of stone
     * @param ostone - Address of ostone(PT) token
     * @param ystone - Address of ystone(YT) token
     * @param dataFeed - Address of STONE/ETH Chainlink dataFeed
     */
    constructor(
        address owner, 
        address stone,
        address ostone, 
        address ystone,
        address dataFeed,
        string memory uri
    ) ERC1155(uri) Ownable(owner) {
        STONE = stone;
        PT_STONE = ostone;
        YT_STONE = ystone;
        STONE_ETH_DATA_FEED = dataFeed;
    }


    /** view **/
    function revenuePool() external view override returns (address) {
        return _revenuePool;
    }

    function totalStaked() external view override returns (uint256) {
        return _totalStaked;
    }

    function yieldPool() external view override returns (uint256) {
        return _yieldPool;
    }
    
    function totalPrincipalValue() external view override returns (uint256) {
        return _totalPrincipalValue;
    }

    function protocolFeeRate() external view override returns (uint256) {
        return _protocolFeeRate;
    }

    function burnedYTFeeRate() external view override returns (uint256) {
        return _burnedYTFeeRate;
    }

    function forceUnstakeFeeRate() external view override returns (uint256) {
        return _forceUnstakeFeeRate;
    }

    function minLockupDays() external view override returns (uint128) {
        return _minLockupDays;
    }

    function maxLockupDays() external view override returns (uint128) {
        return _maxLockupDays;
    }

    function flashLoanFeeRate() external view returns (FlashLoanFeeRate memory) {
        return _flashLoanFeeRate;
    }

    function avgStakeDays() public view override returns (uint256) {
        return IERC20(YT_STONE).totalSupply() / _totalStaked;
    }

    /**
     * @dev Calculate PT amount
     */
    function calcPTAmount(uint256 stakedAmount, uint256 amountInYT) public view override returns (uint256) {
        uint256 amountInNativeYieldToken = stakedAmount - (amountInYT * _yieldPool / IERC20(YT_STONE).totalSupply());
        return calcNativeTokenAmount(amountInNativeYieldToken);
    }

    /**
     * @dev Calculate native token exchange amount from native yield token amount
     */
    function calcNativeTokenAmount(uint256 nativeYieldTokenAmount) internal view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(STONE_ETH_DATA_FEED).latestRoundData();
        return Math.mulDiv(nativeYieldTokenAmount, uint256(answer), 1e18);
    }

    /**
     * @dev Calculate native yield token exchange amount from native token amount
     */
    function calcNativeYieldTokenAmount(uint256 nativeTokenAmount) internal view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(STONE_ETH_DATA_FEED).latestRoundData();
        return Math.mulDiv(nativeTokenAmount, 1e18, uint256(answer));
    }

    /** setter **/
    /**
     * @param revenuePool_ - Address of revenue pool
     */
    function setRevenuePool(address revenuePool_) public override onlyOwner {
        _revenuePool = revenuePool_;
        emit SetRevenuePool(revenuePool_);
    }

    /**
     * @param protocolFeeRate_ - Protocol fee rate
     */
    function setProtocolFeeRate(uint256 protocolFeeRate_) public override onlyOwner {
        require(protocolFeeRate_ <= RATIO, FeeRateOverflow());

        _protocolFeeRate = protocolFeeRate_;
        emit SetProtocolFeeRate(protocolFeeRate_);
    }

    /**
     * @param burnedYTFeeRate_ - Burn more YT when force unstake
     */
    function setBurnedYTFeeRate(uint256 burnedYTFeeRate_) public override onlyOwner {
        require(burnedYTFeeRate_ <= RATIO, FeeRateOverflow());

        _burnedYTFeeRate = burnedYTFeeRate_;
        emit SetBurnedYTFeeRate(burnedYTFeeRate_);
    }

    /**
     * @param forceUnstakeFeeRate_ - Force unstake fee rate
     */
    function setForceUnstakeFeeRate(uint256 forceUnstakeFeeRate_) public override onlyOwner {
        require(forceUnstakeFeeRate_ <= RATIO, FeeRateOverflow());

        _forceUnstakeFeeRate = forceUnstakeFeeRate_;
        emit SetForceUnstakeFeeRate(forceUnstakeFeeRate_);
    }

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
     * @param providerFeeRate_ - FlashLoan provider fee rate
     * @param protocolFeeRate_ - FlashLoan protocol fee rate
     */
    function setFlashLoanFeeRate(uint128 providerFeeRate_, uint128 protocolFeeRate_) public override onlyOwner {
        require(providerFeeRate_ + protocolFeeRate_ <= RATIO, FeeRateOverflow());

        _flashLoanFeeRate = FlashLoanFeeRate(providerFeeRate_, protocolFeeRate_);
        emit SetFlashLoanFeeRate(providerFeeRate_, protocolFeeRate_);
    }

    
    /** function **/
    /**
     * @dev Initializer
     * @param revenuePool_ - Address of revenuePool
     * @param protocolFeeRate_ - protocol fee rate
     * @param burnedYTFeeRate_ - Burn more YT when force unstake
     * @param forceUnstakeFeeRate_ - Force unstake fee tate
     * @param minLockupDays_ - Min lockup days
     * @param maxLockupDays_ - Max lockup days
     * @param flashLoanProviderFeeRate_ - FlashLoan provider fee rate
     * @param flashLoanProtocolFeeRate_ - FlashLoan protocol fee rate
     */
    function initialize(
        address revenuePool_,
        uint256 protocolFeeRate_, 
        uint256 burnedYTFeeRate_,
        uint256 forceUnstakeFeeRate_, 
        uint128 minLockupDays_, 
        uint128 maxLockupDays_,
        uint128 flashLoanProviderFeeRate_, 
        uint128 flashLoanProtocolFeeRate_
    ) external override initializer {
        setRevenuePool(revenuePool_);
        setProtocolFeeRate(protocolFeeRate_);
        setBurnedYTFeeRate(burnedYTFeeRate_);
        setForceUnstakeFeeRate(forceUnstakeFeeRate_);
        setMinLockupDays(minLockupDays_);
        setMaxLockupDays(maxLockupDays_);
        setFlashLoanFeeRate(flashLoanProviderFeeRate_, flashLoanProtocolFeeRate_);
    }

     /**
     * @dev Allows user to deposit native yield token, then mints PT, YT and POT for the user.
     * @param stakedAmount - Staked amount of native yield token
     * @param lockupDays - User can withdraw after lockupDays
     * @param positionOwner - Owner of position
     * @param ptRecipient - Receiver of PT
     * @param ytRecipient - Receiver of YT
     * @notice User must have approved this contract to spend native yield token
     */
    function stake(
        uint256 stakedAmount,
        uint256 lockupDays, 
        address positionOwner, 
        address ptRecipient, 
        address ytRecipient
    ) external override returns (uint256 amountInPT, uint256 amountInYT) {
        require(stakedAmount >= MINSTAKE, MinStakeInsufficient(MINSTAKE));
        uint256 minLockupDays_ = _minLockupDays;
        uint256 maxLockupDays_ = _maxLockupDays;
        require(
            lockupDays >= minLockupDays_ && lockupDays <= maxLockupDays_, 
            InvalidLockupDays(minLockupDays_, maxLockupDays_)
        );

        address msgSender = msg.sender;
        IERC20(STONE).safeTransferFrom(msgSender, address(this), stakedAmount);

        // Calculate principal value
        uint256 constPrincipalValue = calcNativeTokenAmount(stakedAmount);
        uint256 deadline;
        unchecked {
            _totalStaked += stakedAmount;
            _totalPrincipalValue += constPrincipalValue;
            deadline = block.timestamp + lockupDays * DAY;
            amountInYT = stakedAmount * lockupDays;
        }

        IYSTONE(YT_STONE).mint(ytRecipient, amountInYT);
        amountInPT = calcPTAmount(stakedAmount, amountInYT);
        uint256 positionId = _nextId();
        positions[positionId] = Position(stakedAmount, constPrincipalValue, amountInPT, deadline);
        _mint(positionOwner, positionId, amountInPT, "");
        IOSTONE(PT_STONE).mint(ptRecipient, amountInPT);

        emit Stake(positionId, stakedAmount, constPrincipalValue, amountInPT, amountInYT, deadline);
    }

    /**
     * @dev Allows user to unstake funds. If force unstake, need to pay force unstake fee.
     * @param positionId - Staked native yield token position Id
     * @param share - Share of the position
     */
    function unstake(uint256 positionId, uint256 share) external override {
        address msgSender = msg.sender;
        burn(msgSender, positionId, share);

        Position storage position = positions[positionId];
        uint256 stakedAmount = position.stakedAmount;
        uint256 amountInPT = position.amountInPT;
        uint256 principalValue = position.principalValue;

        IOSTONE(PT_STONE).burn(msgSender, share);
        uint256 reducedPrincipalValue = principalValue * share / amountInPT;
        uint256 reducedAmount = calcNativeYieldTokenAmount(reducedPrincipalValue);

        unchecked {
            _totalStaked -= reducedAmount;
            _totalPrincipalValue -= reducedPrincipalValue;
        }

        uint256 burnedYTAmount;
        uint256 forceUnstakeFee;
        uint256 currentTime = block.timestamp;
        uint256 deadline = position.deadline;
        uint256 amountInSTONE = Math.mulDiv(stakedAmount, share, amountInPT, Math.Rounding.Ceil);
        if (deadline > currentTime) {
            unchecked {
                burnedYTAmount = amountInSTONE * Math.ceilDiv(deadline - currentTime, DAY) * (RATIO + _burnedYTFeeRate) / RATIO;
            }
            IYSTONE(YT_STONE).burn(msgSender, burnedYTAmount);
            position.deadline = currentTime;

            unchecked {
                forceUnstakeFee = reducedAmount * _forceUnstakeFeeRate / RATIO;
                reducedAmount -= forceUnstakeFee;
            }
            IERC20(STONE).safeTransfer(_revenuePool, forceUnstakeFee);
        }        
        IERC20(STONE).safeTransfer(msgSender, reducedAmount);

        emit Unstake(positionId, reducedAmount, share, burnedYTAmount, forceUnstakeFee);
    }

    /**
     * @dev Accumulate STONE yield
     */
    function accumYield() public override {
        uint256 totalValue = calcNativeTokenAmount(_totalStaked);

        if (totalValue > _totalPrincipalValue) {
            uint256 nativeYield = totalValue - _totalPrincipalValue;
            uint256 stoneYield = calcNativeYieldTokenAmount(nativeYield);
            uint256 yieldPoolAmount = _yieldPool;
            if (stoneYield > yieldPoolAmount) {
                uint256 increasedYield = stoneYield - yieldPoolAmount;
                if (_protocolFeeRate > 0) {
                    uint256 feeAmount;
                    unchecked {
                        feeAmount = increasedYield * _protocolFeeRate / RATIO;
                        stoneYield -= feeAmount;
                        _totalStaked -= feeAmount;
                    }
                    IERC20(STONE).safeTransfer(_revenuePool, feeAmount);
                }

                unchecked {
                    _yieldPool = stoneYield;
                }

                emit AccumYield(increasedYield);
            }
        }
    }

    /**
     * @dev Allows user burn YT to withdraw yield
     * @param burnedYTAmount - Amount of burned YT
     */
    function withdrawYield(uint256 burnedYTAmount) external override returns (uint256 yieldAmount) {
        require(burnedYTAmount != 0, ZeroInput());
        accumYield();

        unchecked {
            yieldAmount = _yieldPool * burnedYTAmount / IYSTONE(YT_STONE).totalSupply();
            _yieldPool -= yieldAmount;
            _totalStaked -= yieldAmount;
        }

        address msgSender = msg.sender;
        IYSTONE(YT_STONE).burn(msgSender, burnedYTAmount);
        IERC20(STONE).safeTransfer(msgSender, yieldAmount);

        emit WithdrawYield(msgSender, burnedYTAmount, yieldAmount);
    }

    /**
     * @dev STONE FlashLoan service
     * @param receiver - Address of receiver
     * @param amount - Amount of STONE loan
     * @param data - Additional data
     */
    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external override nonReentrant {
        require(amount != 0 && receiver != address(0), ZeroInput());

        uint256 balanceBefore = IERC20(STONE).balanceOf(address(this));
        IERC20(STONE).safeTransfer(receiver, amount);
        IOutFlashCallee(receiver).onFlashLoan(msg.sender, amount, data);

        uint256 balanceAfter;
        uint256 providerFeeAmount;
        uint256 protocolFeeAmount;
        unchecked {
            providerFeeAmount = amount * _flashLoanFeeRate.providerFeeRate / RATIO;
            protocolFeeAmount = amount * _flashLoanFeeRate.protocolFeeRate / RATIO;
            balanceAfter = IERC20(STONE).balanceOf(address(this));
            require(
                balanceAfter >= balanceBefore + providerFeeAmount + protocolFeeAmount, 
                FlashLoanRepayFailed() 
            );
            _totalStaked = balanceAfter - protocolFeeAmount;
        }
        IERC20(STONE).safeTransfer(_revenuePool, protocolFeeAmount);

        emit FlashLoan(receiver, amount, providerFeeAmount, protocolFeeAmount);
    }
}
