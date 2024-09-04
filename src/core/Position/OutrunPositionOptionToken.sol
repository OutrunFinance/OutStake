//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libraries/SYUtils.sol";
import "../libraries/TokenHelper.sol";
import "../common/OutrunERC1155.sol";
import "../common/AutoIncrementId.sol";
import "./interfaces/IOutrunStakeManager.sol";
import "../StandardizedYield/IStandardizedYield.sol";
import "../YieldContracts/interfaces/IYieldToken.sol";
import "../YieldContracts/interfaces/IYieldManager.sol";
import "../YieldContracts/interfaces/IPrincipalToken.sol";

/**
 * @title Outrun Position Option Token
 */
contract OutrunPositionOptionToken is IOutrunStakeManager, OutrunERC1155, TokenHelper, Ownable, AutoIncrementId {
    uint256 public constant DAY = 24 * 3600;
    address public immutable SY;
    address public immutable PT;
    address public immutable YT;

    uint256 public minStake;
    uint256 public syTotalStaking;
    uint256 public totalPrincipalAssetValue;
    LockupDuration public lockupDuration;

    mapping(uint256 positionId => Position) public positions;

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 minStake_,
        address _SY,
        address _PT,
        address _YT
    ) OutrunERC1155(name_, symbol_, decimals_) Ownable(owner_) {
        SY = _SY;
        PT = _PT;
        YT = _YT;
        minStake = minStake_;
    }

    modifier onlyYT() {
        require(msg.sender == YT, PermissionDenied());
        _;
    }
    
    function _transferSY(address receiver, uint256 syAmount) internal {
        unchecked {
            syTotalStaking -= syAmount;
        }

        _transferOut(SY, receiver, syAmount);
    }

    /**
     * @dev Average SY Staking Duration in Days
     */
    function syAvgStakingDays() external view override returns (uint256) {
        return IERC20(YT).totalSupply() / syTotalStaking;
    }

    /**
     * @dev Calculate PT amount by YT amount and principal value
     */
    function calcPTAmount(uint256 principalAssetValue, uint256 amountInYT) public view override returns (uint256) {
        return principalAssetValue - (amountInYT * IYieldManager(YT).totalRedeemableYields() / IERC20(YT).totalSupply());
    }

    /**
     * @param _minLockupDays - Min lockup days
     * @param _maxLockupDays - Max lockup days
     */
    function setLockupDuration(uint128 _minLockupDays, uint128 _maxLockupDays) external override onlyOwner {
        lockupDuration.minLockupDays = _minLockupDays;
        lockupDuration.maxLockupDays = _maxLockupDays;

        emit SetLockupDuration(_minLockupDays, _maxLockupDays);
    }

    /**
     * @dev Allows user to deposit SY, then mints PT, YT and POT for the user.
     * @param stakedSYAmount - Staked amount of SY
     * @param lockupDays - User can redeem after lockupDays
     * @param positionOwner - Owner of position
     * @param PTRecipient - Receiver of PT
     * @param YTRecipient - Receiver of YT
     * @notice User must have approved this contract to spend SY
     */
    function stake(
        uint256 stakedSYAmount,
        uint256 lockupDays, 
        address positionOwner, 
        address PTRecipient, 
        address YTRecipient
    ) external override returns (uint256 amountInPT, uint256 amountInYT) {
        require(stakedSYAmount >= minStake, MinStakeInsufficient(minStake));
        uint256 _minLockupDays = lockupDuration.minLockupDays;
        uint256 _maxLockupDays = lockupDuration.maxLockupDays;
        require(
            lockupDays >= _minLockupDays && lockupDays <= _maxLockupDays, 
            InvalidLockupDays(_minLockupDays, _maxLockupDays)
        );

        address msgSender = msg.sender;
        _transferIn(SY, msgSender, stakedSYAmount);
        
        uint256 deadline;
        uint256 principalAssetValue = SYUtils.syToAsset(IStandardizedYield(SY).exchangeRate(), stakedSYAmount);
        unchecked {
            syTotalStaking += stakedSYAmount;
            totalPrincipalAssetValue += principalAssetValue;
            deadline = block.timestamp + lockupDays * DAY;
            amountInYT = principalAssetValue * lockupDays;
        }

        IYieldToken(YT).mint(YTRecipient, amountInYT);
        amountInPT = calcPTAmount(principalAssetValue, amountInYT);
        uint256 positionId = _nextId();
        positions[positionId] = Position(stakedSYAmount, principalAssetValue, amountInPT, deadline);
        _mint(positionOwner, positionId, amountInPT, "");
        IPrincipalToken(PT).mint(PTRecipient, amountInPT);

        emit Stake(positionId, stakedSYAmount, principalAssetValue, amountInPT, amountInYT, deadline);
    }

    /**
     * @dev Allows user to unstake SY by burnning PT and POT.
     * @param positionId - Position Id
     * @param share - Share of the position
     */
    function redeem(uint256 positionId, uint256 share) external override {
        Position storage position = positions[positionId];
        uint256 deadline = position.deadline;
        require(deadline <= block.timestamp, LockTimeNotExpired(deadline));

        address msgSender = msg.sender;
        burn(msgSender, positionId, share);
        
        uint256 amountInPT = position.amountInPT;
        uint256 principalAssetValue = position.principalAssetValue;

        IPrincipalToken(PT).burn(msgSender, share);
        uint256 reducedAssetValue = principalAssetValue * share / amountInPT;
        uint256 reducedStakedSYAmount = SYUtils.assetToSy(IStandardizedYield(SY).exchangeRate(), reducedAssetValue);

        unchecked {
            totalPrincipalAssetValue -= reducedAssetValue;
        }
        _transferSY(msgSender, reducedStakedSYAmount);

        emit Redeem(positionId, reducedStakedSYAmount, share);
    }

    /**
     * @dev Transfer yields when collecting protocol fees and withdrawing yields, only YT can call
     * @param receiver - Address of receiver
     * @param syAmount - Amount of protocol fee
     */
    function transferYields(address receiver, uint256 syAmount) external override onlyYT {
        require(msg.sender == YT, PermissionDenied());
        _transferSY(receiver, syAmount);
    }
}
