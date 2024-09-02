// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./interfaces/IOutrunLisUSDSY.sol";
import "../../OutrunYieldToken.sol";
import "../../interfaces/IStandardizedYield.sol";
import "../../../libraries/TokenHelper.sol";
import "../../../../external/lista/IListaLisUSDJar.sol";
import "../../../../external/lista/IStakeLisUSDListaDistributor.sol";

contract OutrunLisUSDYieldToken is OutrunYieldToken, TokenHelper, ReentrancyGuard {
    address public immutable listaLisUSDJar;
    address public immutable stakeLisUSDListaDistributor;

    uint256 public accumBalance;

    constructor(
        address owner_,
        address _jar,
        address _distributor,
        address _revenuePool,
        uint256 _protocolFeeRate
    ) OutrunYieldToken(
        "Outrun LisUSD Yield Token",
        "YT-lisUSD",
        18,
        owner_,
        _revenuePool,
        _protocolFeeRate
    ) {
        listaLisUSDJar = _jar;
        stakeLisUSDListaDistributor = _distributor;
    }

    /**
     * @dev See {YieldManager-totalRedeemableYields}
     */
    function totalRedeemableYields() public view override returns (uint256 amount) {
        uint256 amountNotcollected = IListaLisUSDJar(listaLisUSDJar).earned(SY);
        uint256 protocolFee = amountNotcollected * protocolFeeRate / RATIO;
        amount = amountNotcollected - protocolFee + accumBalance;
    }

    /**
     * @dev See {YieldManager-totalRedeemableYields}
     */
    function previewWithdrawYields(uint256 amountInBurnedYT) public view override returns (uint256 amountYieldsOut) {
        amountYieldsOut = amountInBurnedYT * totalRedeemableYields() / totalSupply();
    }

    /**
     * @dev See {YieldManager-accumulateYieldsFromSY}
     */
    function accumulateYieldsFromSY(address nativeYieldToken, uint256 amountInYields) external override {
        address msgSender = msg.sender;
        require(msgSender == SY, PermissionDenied());
    
        _transferIn(nativeYieldToken, msgSender, amountInYields);
        uint256 protocolFee = amountInYields * protocolFeeRate / RATIO;
        unchecked {
            amountInYields -= protocolFee;
            accumBalance += amountInYields;
        }
        _transferOut(nativeYieldToken, revenuePool, protocolFee);

        emit AccumulateYields(amountInYields, protocolFee);
    }

    /**
     * @dev See {YieldManager-withdrawYields}
     */
    function withdrawYields(uint256 amountInBurnedYT) external override nonReentrant returns (uint256 amountYieldsOut) {
        address msgSender = msg.sender;
        _burn(msgSender, amountInBurnedYT);

        amountYieldsOut = previewWithdrawYields(amountInBurnedYT);
        if (accumBalance < amountYieldsOut) {
            IOutrunLisUSDSY(SY).replenishYieldBalance();
        }
        _transferOut(IStandardizedYield(SY).nativeYieldToken(), msgSender, amountYieldsOut);

        emit WithdrawYields(msgSender, amountYieldsOut);
    }
}
