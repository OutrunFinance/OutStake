//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IUSDBStakeManager {
    function stake(uint256 amount) external payable ;

    function unStake(uint256 amount) external;

    function getVaultUSDB() external returns (uint256);

    function convertToBUSD(uint256 amountInUSDB) external returns (uint256);

    function convertToUSDB(uint256 amountInBUSD) external returns (uint256);

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
