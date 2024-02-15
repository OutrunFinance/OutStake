//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IBETHYieldPool} from "./interfaces/IBETHYieldPool.sol";
import {IBETH} from "../token/ETH/interfaces/IBETH.sol";
import {IBEYT} from "../token/ETH/interfaces/IBEYT.sol";

/**
 * @title BETH Yield Pool
 */
contract BETHYieldPool is IBETHYieldPool {
    using SafeERC20 for IERC20;

    address public immutable bETH;
    address public immutable bEYT;

    /**
     * @param _bETH - Address of BETH Token
     * @param _bEYT - Address of BEYT Token
     */
    constructor(address _bETH, address _bEYT) {
        bETH = _bETH;
        bEYT = _bEYT;
    }

    /**
     * @dev Allows user burn BEYT to  withdraw yield
     * @param amountInBEYT - Amount of BEYT
     */
    function withdraw(uint256 amountInBEYT) public override {
        require(amountInBEYT > 0, "Invalid Amount");

        address user = msg.sender;
        IBEYT(bEYT).burn(user, amountInBEYT);

        uint256 _yieldAmount = Math.mulDiv(
            IBETH(bETH).balanceOf(address(this)),
            amountInBEYT,
            IBEYT(bEYT).totalSupply()
        );
        IERC20(bETH).safeTransfer(user, _yieldAmount);

        emit Withdraw(user, amountInBEYT, _yieldAmount);
    }

    receive() external payable {}
}