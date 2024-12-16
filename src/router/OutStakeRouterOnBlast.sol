// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { OutStakeRouter } from "./OutStakeRouter.sol";
import { BlastGovernorable } from "../external/blast/BlastGovernorable.sol";


contract OutStakeRouterOnBlast is OutStakeRouter, BlastGovernorable {
    constructor(address _blastGovernor) OutStakeRouter() BlastGovernorable(_blastGovernor) {}
}
