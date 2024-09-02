// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../yield/OutrunPrincipalToken.sol";
import "../../yield/interfaces/IStandardizedYield.sol";

/**
 * @dev Outrun universal BNB principal token, can be minted from various BNB native yield tokens
 */
contract UniversalBNBPrincipalToken is OutrunPrincipalToken {
    constructor(address owner) OutrunPrincipalToken(owner, "Universal BNB Principal Token", "UBNB", 18) {}
}
