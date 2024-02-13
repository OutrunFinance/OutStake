//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IETHStakeManager} from "./interfaces/IETHStakeManager.sol";
import {IBETH} from "../token/interfaces/IBETH.sol";
import {IPETH} from "../token/interfaces/IPETH.sol";

/**
 * @title ETH Stake Manager Contract
 * @dev Handles Staking of ETH
 */
contract ETHStakeManager is IETHStakeManager, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public constant THOUSAND = 1000;
    uint256 public constant PRECISION = 1e15;
    bytes32 public constant BOT = keccak256("BOT");

    address public bETH;
    address public pETH;
    address public manager;
    uint256 public minIntervalTime;
    uint256 public maxIntervalTime;

    /**
     * @param _bETH - Address of BETH Token
     * @param _pETH - Address of PETH Token
     * @param _admin - Address of the admin
     * @param _bot - Address of the Bot
     * @param _minIntervalTime - Min lock interval time
     * @param _maxIntervalTime - Max lock interval time
     */
    constructor(
        address _bETH,
        address _pETH,
        address _admin,
        address _bot,
        uint256 _minIntervalTime,
        uint256 _maxIntervalTime,
    ) {
        require(
            ((_bETH != address(0)) &&
            (_pETH != address(0)) &&
            (_admin != address(0)) &&
            (_bot != address(0))),
            "Zero address provided"
        );

        bETH = _bETH;
        pETH = _pETH;
        minIntervalTime = _minIntervalTime;
        maxIntervalTime =_maxIntervalTime;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * 用户stake BETH，指定一个锁定到期时间deadLine，锁定到期前不可unstake，铸造相同数量的PETH和与锁定时间相关的收益Token
     *
     * @dev Allows user to deposit BETH, then mints PETH and YieldToken for the user.
     * @param amount BETH staked amount, amount % 1e15 == 0
     * @param deadLine User can unstake after deadLine
     */
    function stake(uint256 amount, uint256 deadLine) external override {
        require(amount % PRECISION == 0 && amount != 0, "Invalid Amount");
        uint256 intervalTime = deadLine - block.timestamp;
        require(
            deadLine>= minIntervalTime + block.timestamp &&
            deadLine <= maxIntervalTime + block.timestamp ,
            "LockTime Invalid"
        );

        IERC20(bETH).safeTransferFrom(msg.sender, address(this), amount);
        IPETH(pETH).mint(msg.sender, amount);

        // TODO 铸造YieldToken

        emit StakeETH(msg.sender, amount, deadLine);
    }

    /**
     * 用户unstake,首先判断锁定时间是否已过期，否则不能unstake。
     * 然后将PETH销毁，仅将BETH取出来
     *
     * @dev Allows user to unstake funds
     * @param amount - Amount of BETH for burn
     * @param positionId - NFT tokenId
     * @notice User must have approved this contract to spend BETH
     */
    function unStake(uint256 amount, uint256 positionId) external override {
        require(amount > 0, "Invalid Amount");

        emit Withdraw(msg.sender, amount);
    }

    function getVaultETH() public view override returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}