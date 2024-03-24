// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IRUSD.sol";
import "../../utils/Initializable.sol";
import "../../blast/GasManagerable.sol";
import "../../vault/interfaces/IOutUSDBVault.sol";

/**
 * @title Outrun USD Wrapped Token
 */
contract RUSD is IRUSD, ERC20, Initializable, Ownable, GasManagerable {
    using SafeERC20 for IERC20;

    address public constant USDB = 0x4200000000000000000000000000000000000022;
    address private _outUSDBVault;

    modifier onlyOutUSDBVault() {
        if (msg.sender != _outUSDBVault) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner, address gasManager) ERC20("Outrun Wrapped USDB", "RUSD") Ownable(owner) GasManagerable(gasManager) {}

    function outUSDBVault() external view override returns (address) {
        return _outUSDBVault;
    }

    /**
     * @dev Initializer
     * @param _vault - Address of OutUSDBVault
     */
    function initialize(address _vault) external override initializer {
        setOutUSDBVault(_vault);
    }

    /**
     * @dev Allows user to deposit USDB and mint RUSD
     * @notice User must have approved this contract to spend USDB
     */
    function deposit(uint256 amount) external override {
        if (amount == 0) {
            revert ZeroInput();
        }
        address user = msg.sender;
        IERC20(USDB).safeTransferFrom(user, _outUSDBVault, amount);
        _mint(user, amount);

        emit Deposit(user, amount);
    }

    /**
     * @dev Allows user to withdraw USDB by RUSD
     * @param amount - Amount of RUSD for burn
     */
    function withdraw(uint256 amount) external override {
        if (amount == 0) {
            revert ZeroInput();
        }
        address user = msg.sender;
        _burn(user, amount);
        IOutUSDBVault(_outUSDBVault).withdraw(user, amount);

        emit Withdraw(user, amount);
    }

    /**
     * @dev OutETHVault fee
     */
    function mint(address _account, uint256 _amount) external override onlyOutUSDBVault {
        _mint(_account, _amount);
    }
    
    function setOutUSDBVault(address _vault) public override onlyOwner {
        _outUSDBVault = _vault;
        emit SetOutUSDBVault(_vault);
    }
}