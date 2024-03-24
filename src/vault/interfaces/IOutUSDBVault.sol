//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutUSDBVault {
    struct FlashLoanFee {
        uint256 providerFeeRate;
        uint256 protocolFeeRate;
    }


    /** error **/
    error ZeroInput();

    error PermissionDenied();

    error FeeRateOverflow();

    error FlashLoanRepayFailed();


    /** view **/
    function RUSDStakeManager() external view returns (address);

    function revenuePool() external view returns (address);

    function protocolFee() external view returns (uint256);

    function flashLoanFee() external view returns (FlashLoanFee memory);


    /** setter **/
    function setProtocolFee(uint256 _protocolFee) external;

    function setFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate) external;

    function setRevenuePool(address _pool) external;

    function setRUSDStakeManager(address _RUSDStakeManager) external;


    /** function **/
    function initialize(
        address stakeManager_, 
        address revenuePool_, 
        uint256 protocolFee_, 
        uint256 providerFeeRate_, 
        uint256 protocolFeeRate_
    ) external;
    
    function withdraw(address user, uint256 amount) external;

    function claimUSDBYield() external returns (uint256);

    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external;


    /** event **/
    event ClaimUSDBYield(uint256 amount);
    
    event FlashLoan(address indexed receiver, uint256 amount);

    event SetProtocolFee(uint256 _protocolFee);

    event SetFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate);

    event SetRevenuePool(address _pool);

    event SetRUSDStakeManager(address _RUSDStakeManager);
}