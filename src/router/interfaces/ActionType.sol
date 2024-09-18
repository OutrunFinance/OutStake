// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

enum TokenType {
    NONE,
    ETH_WETH
}

struct TokenInput {
    address tokenIn;
    uint256 amount;
    address depositedToken;
    TokenType tokenType;
}

struct TokenOutput {
    address tokenOut;
    uint256 minTokenOut;
    address redeemedToken;
    TokenType tokenType;
}
