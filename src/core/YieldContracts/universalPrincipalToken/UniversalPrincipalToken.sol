// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../OutrunPrincipalToken.sol";

/**
 * @dev Outrun universal principal token
 */
contract UniversalPrincipalToken is OutrunPrincipalToken {
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) OutrunPrincipalToken(owner_, name_, symbol_, decimals_) {
    }
}
