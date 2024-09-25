// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "../OutrunPrincipalToken.sol";
import "../../../external/blast/GasManagerable.sol";

/**
 * @dev Outrun universal principal token on Blast
 */
contract UniversalPrincipalTokenOnBlast is OutrunPrincipalToken, GasManagerable {
    constructor(
        address owner_,
        address gasManager_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) OutrunPrincipalToken(owner_, name_, symbol_, decimals_) GasManagerable(gasManager_) {
    }
}
