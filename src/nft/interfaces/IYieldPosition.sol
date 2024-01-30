// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import {IYieldPosition} from "../nft/interfaces/IYieldPosition.sol";

interface YieldPosition {
    
    struct Position {
        uint256 tokenId;
        uint256 credential; // 收益凭证
        uint256 principal;  // 本金
        uint256 deadLine;
    }

    function mint(address to, string memory uri, Position memory position) external;
}
