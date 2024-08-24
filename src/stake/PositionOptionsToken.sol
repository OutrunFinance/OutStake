//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/**
 * @title Position Options Token
 */
abstract contract PositionOptionsToken is ERC1155Supply {
    string public name = "Position Options Token";
    string public symbol = "POT";
    uint8 public decimals = 18;

    struct Position {
        address stakedToken;
        uint128 stakedAmount;
        uint128 PTAmount;
        uint256 deadline;
    }

    mapping(uint256 positionId => Position) public positions;
    
    function burn(address account, uint256 id, uint256 value) public {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        _burnBatch(account, ids, values);
    }
}
