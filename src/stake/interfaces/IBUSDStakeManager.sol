//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

 /**
  * @title IBUSDStakeManager interface
  */
interface IBUSDStakeManager {
    function stake(uint256 amount) external payable ;

    function unStake(uint256 amount) external;

    function getVaultBUSD() external returns (uint256);

    function convertToPUSD(uint256 amountInUSDB) external returns (uint256);

    function convertToBUSD(uint256 amountInBUSD) external returns (uint256);

    function compoundRewards() external;

    function setBotRole(address _address) external;

    function revokeBotRole(address _address) external;
    
    function setFeeRate(uint256 _feeRate) external;

    function setRevenuePool(address _address) external;

    event Stake(address indexed _account, uint256 _amount);

    event UnStake(address indexed _account, uint256 _amountInUSDB);

    event RewardsCompounded(uint256 _amount);

    event SetFeeRate(uint256 _feeRate);

    event SetRevenuePool(address indexed _address);
}
