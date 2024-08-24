// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 /**
  * @title ORUSD interface
  */
interface IORUSD is IERC20 {
	struct FlashLoanFee {
		uint256 providerFeeRate;
		uint256 protocolFeeRate;
	}

	error ZeroInput();

	error PermissionDenied();

	error FeeRateOverflow();

	error FlashLoanRepayFailed();


    function ORUSDStakeManager() external view returns (address);

    function revenuePool() external view returns (address);

    function protocolFee() external view returns (uint256);

    function flashLoanFee() external view returns (FlashLoanFee memory);


    function setAutoBot(address _bot) external;
    
    function setProtocolFee(uint256 _protocolFee) external;

    function setFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate) external;

    function setRevenuePool(address _pool) external;

    function setORUSDStakeManager(address _orUSDStakeManager) external;


    function initialize(address stakeManager_) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function accumUSDBYield() external returns (uint256 nativeYield, uint256 dayRate);

    function flashLoan(address receiver, uint256 amount, bytes calldata data) external;


    event SetAutoBot(address _bot);

	event SetORUSDStakeManager(address _orUSDStakeManager);

	event SetRevenuePool(address _pool);

    event SetProtocolFee(uint256 _protocolFee);

    event SetFlashLoanFee(uint256 _providerFeeRate, uint256 _protocolFeeRate);

	event Deposit(address indexed _account, uint256 _amount);

    event Withdraw(address indexed _account, uint256 _amount);

	event AccumUSDBYield(uint256 amount, uint256 dayRate);
    
    event FlashLoan(address indexed receiver, uint256 amount);
}