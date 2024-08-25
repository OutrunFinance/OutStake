//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import "./PositionOptionsToken.sol";
import "../utils/Initializable.sol";
import "../utils/AutoIncrementId.sol";
import "../utils/IOutFlashCallee.sol";
import "../external/lista/IStakeManager.sol";
import "../token/slisBNB/interfaces/IOSlisBNB.sol";
import "../token/slisBNB/interfaces/IYSlisBNB.sol";
import "./interfaces/IListaBNBStakeManager.sol";

/**
 * @title ListaBNB Stake Manager Contract
 * @dev Handles Staking of slisBNB
 */
contract ListaBNBStakeManager is IListaBNBStakeManager, PositionOptionsToken, Initializable, ReentrancyGuard, Ownable, AutoIncrementId {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO = 10000;
    uint256 public constant MINSTAKE = 1e16;
    uint256 public constant DAY = 24 * 3600;

    address public immutable SLISBNB;
    address public immutable PT_SLISBNB;
    address public immutable YT_SLISBNB;
    address public immutable LISTA_STAKE_MANAGER;

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
     * @param slisBNB - Address of slisBNB
     * @param oslisBNB - Address of oslisBNB(PT) token
     * @param yslisBNB - Address of yslisBNB(YT) token
     * @param listaStakeManager - Address of listaStakeManager
     */
    constructor(
        address owner, 
        address slisBNB,
        address oslisBNB, 
        address yslisBNB,
        address listaStakeManager,
        string memory uri
    ) ERC1155(uri) Ownable(owner) {
        SLISBNB = slisBNB;
        PT_SLISBNB = oslisBNB;
        YT_SLISBNB = yslisBNB;
        LISTA_STAKE_MANAGER = listaStakeManager;
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
        return IERC20(YT_SLISBNB).totalSupply() / _totalStaked;
    }

    function calcPTAmount(uint256 nativeYieldTokenAmount, uint256 amountInYT) public view override returns (uint256 amountInNativeToken) {
        uint256 amountInNativeYieldToken = nativeYieldTokenAmount - (amountInYT * _yieldPool / IERC20(YT_SLISBNB).totalSupply());
        amountInNativeToken = IStakeManager(LISTA_STAKE_MANAGER).convertSnBnbToBnb(amountInNativeYieldToken);
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
     * @param lockupDays - User can withdraw after lockupDays
     * @param positionOwner - Owner of position
     * @param pslisBNBTo - Receiver of pslisBNB(PT)
     * @param yslisBNBTo - Receiver of yslisBNB(YT)
     * @notice User must have approved this contract to spend native yield token
     */
    function stake(
        uint256 slisBNBAmount,
        uint256 lockupDays, 
        address positionOwner, 
        address pslisBNBTo, 
        address yslisBNBTo
    ) external override returns (uint256 amountInPT, uint256 amountInYT) {
        require(slisBNBAmount >= MINSTAKE, MinStakeInsufficient(MINSTAKE));
        require(
            lockupDays >= _minLockupDays && lockupDays <= _maxLockupDays, 
            InvalidLockupDays(_minLockupDays, _maxLockupDays)
        );

        address msgSender = msg.sender;
        IERC20(SLISBNB).safeTransferFrom(msgSender, address(this), slisBNBAmount);
        uint256 constPrincipalValue = IStakeManager(LISTA_STAKE_MANAGER).convertSnBnbToBnb(slisBNBAmount);

        uint256 deadline;
        unchecked {
            _totalStaked += slisBNBAmount;
            _totalPrincipalValue += constPrincipalValue;
            deadline = block.timestamp + lockupDays * DAY;
            amountInYT = slisBNBAmount * lockupDays;
        }

        IYSlisBNB(YT_SLISBNB).mint(yslisBNBTo, amountInYT);
        amountInPT = calcPTAmount(slisBNBAmount, amountInYT);
        uint256 positionId = _nextId();
        positions[positionId] = Position(slisBNBAmount, constPrincipalValue, amountInPT, deadline);
        _mint(positionOwner, positionId, amountInPT, "");
        IOSlisBNB(PT_SLISBNB).mint(pslisBNBTo, amountInPT);

        emit StakeSlisBNB(positionId, slisBNBAmount, constPrincipalValue, amountInPT, amountInYT, deadline);
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

        IOSlisBNB(PT_SLISBNB).burn(msgSender, share);
        uint256 reducedPrincipalValue = principalValue * share / amountInPT;
        uint256 reducedSlisBNBAmount = IStakeManager(LISTA_STAKE_MANAGER).convertBnbToSnBnb(reducedPrincipalValue);

        unchecked {
            _totalStaked -= reducedSlisBNBAmount;
            _totalPrincipalValue -= reducedPrincipalValue;
        }

        uint256 burnedYTAmount;
        uint256 currentTime = block.timestamp;
        uint256 deadline = position.deadline;
        uint256 amountInSlisBNB = Math.mulDiv(stakedAmount, share, amountInPT);
        if (deadline > currentTime) {
            unchecked {
                burnedYTAmount = amountInSlisBNB * Math.ceilDiv(deadline - currentTime, DAY) * (RATIO + _burnedYTFeeRate) / RATIO;
            }
            IYSlisBNB(YT_SLISBNB).burn(msgSender, burnedYTAmount);
            position.deadline = currentTime;

            uint256 fee;
            unchecked {
                fee = reducedSlisBNBAmount * _forceUnstakeFeeRate / RATIO;
                reducedSlisBNBAmount -= fee;
            }
            IERC20(SLISBNB).safeTransfer(_revenuePool, fee);
        }        
        IERC20(SLISBNB).safeTransfer(msgSender, reducedSlisBNBAmount);

        emit Unstake(positionId, reducedSlisBNBAmount, share, burnedYTAmount);
    }

    /**
     * @dev Accumulate slisBNB yield
     */
    function accumSlisBNBYield() external override {
        uint256 totalValue = IStakeManager(LISTA_STAKE_MANAGER).convertSnBnbToBnb(_totalStaked);

        if (totalValue > _totalPrincipalValue) {
            uint256 nativeYield = totalValue - _totalPrincipalValue;
            uint256 slisBNBYield = IStakeManager(LISTA_STAKE_MANAGER).convertBnbToSnBnb(nativeYield);
            if (slisBNBYield > _yieldPool) {
                uint256 increasedYield = slisBNBYield - _yieldPool;
                if (_protocolFeeRate > 0) {
                    uint256 feeAmount;
                    unchecked {
                        feeAmount = increasedYield * _protocolFeeRate / RATIO;
                        slisBNBYield -= feeAmount;
                        _totalStaked -= feeAmount;
                    }
                    IERC20(SLISBNB).safeTransfer(_revenuePool, feeAmount);
                }

                unchecked {
                    _yieldPool = slisBNBYield;
                }

                emit AccumSlisBNBYield(increasedYield);
            }
        }
    }

    /**
     * @dev Allows user burn YT to withdraw yield
     * @param burnedYTAmount - Amount of burned YT
     */
    function withdrawYield(uint256 burnedYTAmount) external override returns (uint256 yieldAmount) {
        require(burnedYTAmount != 0, ZeroInput());

        unchecked {
            yieldAmount = _yieldPool * burnedYTAmount / IYSlisBNB(YT_SLISBNB).totalSupply();
            _yieldPool -= yieldAmount;
            _totalStaked -= yieldAmount;
        }

        address msgSender = msg.sender;
        IYSlisBNB(YT_SLISBNB).burn(msgSender, burnedYTAmount);
        IERC20(SLISBNB).safeTransfer(msgSender, yieldAmount);

        emit WithdrawYield(msgSender, burnedYTAmount, yieldAmount);
    }

    /**
     * @dev slisBNB FlashLoan service
     * @param receiver - Address of receiver
     * @param amount - Amount of slisBNB loan
     * @param data - Additional data
     */
    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external override nonReentrant {
        require(amount != 0 && receiver != address(0), ZeroInput());

        uint256 balanceBefore = _totalStaked;
        IERC20(SLISBNB).safeTransfer(receiver, amount);
        IOutFlashCallee(receiver).onFlashLoan(msg.sender, amount, data);

        uint256 balanceAfter;
        uint256 providerFeeAmount;
        uint256 protocolFeeAmount;
        unchecked {
            providerFeeAmount = amount * _flashLoanFeeRate.providerFeeRate / RATIO;
            protocolFeeAmount = amount * _flashLoanFeeRate.protocolFeeRate / RATIO;
            balanceAfter = IERC20(SLISBNB).balanceOf(address(this));
            require(
                balanceAfter >= balanceBefore + providerFeeAmount + protocolFeeAmount, 
                FlashLoanRepayFailed() 
            );
            _totalStaked = balanceAfter - protocolFeeAmount;
        }
        IERC20(SLISBNB).safeTransfer(_revenuePool, protocolFeeAmount);

        emit FlashLoan(receiver, amount, providerFeeAmount, protocolFeeAmount);
    }
}
