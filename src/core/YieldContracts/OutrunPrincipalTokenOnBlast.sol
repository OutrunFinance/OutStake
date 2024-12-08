// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.26;

import { OutrunPrincipalToken } from "./OutrunPrincipalToken.sol";
import { GasManagerable } from "../../external/blast/GasManagerable.sol";

contract OutrunPrincipalTokenOnBlast is OutrunPrincipalToken, GasManagerable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner_,
        address gasManager_
    ) OutrunPrincipalToken(name_, symbol_, decimals_, owner_) GasManagerable(gasManager_) {
    }
}
