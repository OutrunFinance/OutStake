// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { BlastGovernorable } from "../../external/blast/BlastGovernorable.sol";
import { OutrunUniversalPrincipalToken } from "./OutrunUniversalPrincipalToken.sol";

/**
 * @dev Outrun Universal Principal Token On Blast
 */
contract OutrunUniversalPrincipalTokenOnBlast is OutrunUniversalPrincipalToken, BlastGovernorable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address _lzEndpoint,
        address _delegate,
        address _blastGovernor
    ) OutrunUniversalPrincipalToken(name_, symbol_, decimals_, _lzEndpoint, _delegate) BlastGovernorable(_blastGovernor) {
    }
}
