// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../yield/OutrunPrincipalToken.sol";
import "../../yield/interfaces/IStandardizedYield.sol";

/**
 * @dev Outrun universal USD principal token, can be minted from various USD native yield tokens
 */
contract UniversalUSDPrincipalToken is OutrunPrincipalToken {
    constructor(address owner) OutrunPrincipalToken(owner, "Universal USD Principal Token", "UUSD", 18) {}
}
