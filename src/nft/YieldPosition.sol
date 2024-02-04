// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IYieldPosition} from "./interfaces/IYieldPosition.sol";

contract YieldPosition is
    IYieldPosition,
    ERC721URIStorage,
    ERC721Royalty,
    ERC721Burnable,
    Ownable
{   
    uint256 private _nextTokenId;

    mapping(uint256 tokenId => Position position) public positions;

    constructor(
        address initialOwner
    ) ERC721("YieldPosition", "YP") Ownable(initialOwner) {}

    function mint(
        address to,
        string memory uri,
        Position memory position
    ) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        positions[tokenId] = position;
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
