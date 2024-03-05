//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IOutUSDBVault {
    struct FlashLoanFee {
        uint256 providerFeeRate;
        uint256 protocolFeeRate;
    }

    error ZeroInput();

    error PermissionDenied();

    error FeeRateOverflow();

    error FlashLoanRepayFailed();

    /** view **/
    function RUSDStakeManager() external view returns (address);

    function revenuePool() external view returns (address);

    function feeRate() external view returns (uint256);

    function flashLoanFee() external view returns (FlashLoanFee memory);

    /** function **/
    function initialize() external;
    
    function withdraw(address user, uint256 amount) external;

    function claimUSDBYield() external;

    function flashLoan(address payable receiver, uint256 amount, bytes calldata data) external;

    /** setter **/
    function setFeeRate(uint256 _feeRate) external;

    function setFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate) external;

    function setRevenuePool(address _pool) external;

    function setRUSDStakeManager(address _RUSDStakeManager) external;

    event ClaimUSDBYield(uint256 amount);
    
    event FlashLoan(address indexed receiver, uint256 amount);

    event SetFeeRate(uint256 _feeRate);

    event SetFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate);

    event SetRevenuePool(address _pool);

    event SetRUSDStakeManager(address _RUSDStakeManager);
}