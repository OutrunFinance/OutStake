// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {MyEnumContract} from "./IERC20Enum.sol";
interface IERC20Rebasing {
  // changes the yield mode of the caller and update the balance
  // to reflect the configuration
  function configure(MyEnumContract.YieldMode) external returns (uint256);
  // "claimable" yield mode accounts can call this this claim their yield
  // to another address
  function claim(address recipient, uint256 amount) external returns (uint256);
  // read the claimable amount for an account
  function getClaimableAmount(address account) external view returns (uint256);
}
