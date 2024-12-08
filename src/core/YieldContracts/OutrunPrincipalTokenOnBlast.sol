// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.26;

import { OutrunPrincipalToken } from "./OutrunPrincipalToken.sol";
import { BlastGovernorable } from "../../external/blast/BlastGovernorable.sol";

contract OutrunPrincipalTokenOnBlast is OutrunPrincipalToken, BlastGovernorable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner_,
        address blastGovernor_
    ) OutrunPrincipalToken(name_, symbol_, decimals_, owner_) BlastGovernorable(blastGovernor_) {
    }
}
