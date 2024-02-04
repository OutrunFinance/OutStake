// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IYieldPosition {
    
    struct Position {
        uint256 tokenId;
        uint256 credential; // 收益凭证
        uint256 principal;  // 本金
        uint256 deadLine;
    }

    function mint(address to, string memory uri, Position memory position) external;
}
