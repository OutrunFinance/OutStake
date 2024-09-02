// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../../yield/OutrunPrincipalToken.sol";
import "../../yield/interfaces/IStandardizedYield.sol";

/**
 * @dev Outrun universal ETH principal token, can be minted from various ETH native yield tokens
 */
contract UniversalETHPrincipalToken is OutrunPrincipalToken {
    constructor(address owner) OutrunPrincipalToken(owner, "Universal ETH Principal Token", "UETH", 18) {}
}
