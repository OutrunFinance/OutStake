//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import {IBUSDYieldPool} from "./interfaces/IBUSDYieldPool.sol";
import {IBUSD} from "../token/USDB/interfaces/IBUSD.sol";
import {IBUYT} from "../token/USDB/interfaces/IBUYT.sol";

/**
 * @title BUSD Yield Pool
 */
contract BUSDYieldPool is IBUSDYieldPool {
    using SafeERC20 for IERC20;

    address public immutable bUSD;
    address public immutable bUYT;

    /**
     * @param _bUSD - Address of BUSD Token
     * @param _bUYT - Address of BUYT Token
     */
    constructor(address _bUSD, address _bUYT) {
        bUSD = _bUSD;
        bUYT = _bUYT;
    }

    /**
     * @dev Allows user burn BUYT to  withdraw yield
     * @param amountInBUYT - Amount of BUYT
     */
    function withdraw(uint256 amountInBUYT) public override {
        require(amountInBUYT > 0, "Invalid Amount");

        address user = msg.sender;
        IBUYT(bUYT).burn(user, amountInBUYT);

        uint256 _yieldAmount = Math.mulDiv(
            IBUSD(bUSD).balanceOf(address(this)),
            amountInBUYT,
            IBUYT(bUYT).totalSupply()
        );
        IERC20(bUSD).safeTransfer(user, _yieldAmount);

        emit Withdraw(user, amountInBUYT, _yieldAmount);
    }

    receive() external payable {}
}