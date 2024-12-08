// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.26;

import { OutrunERC4626YieldToken } from "./OutrunERC4626YieldToken.sol";
import { BlastGovernorable } from "../../external/blast/BlastGovernorable.sol";

contract OutrunERC4626YieldTokenOnBlast is OutrunERC4626YieldToken, BlastGovernorable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address owner_,
        address blastGovernor_,
        address revenuePool_,
        uint256 protocolFeeRate_
    ) OutrunERC4626YieldToken(name_, symbol_, decimals_, owner_, revenuePool_, protocolFeeRate_) BlastGovernorable(blastGovernor_) {
    }
}
