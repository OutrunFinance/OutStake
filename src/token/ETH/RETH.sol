// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IRETH.sol";
import "../../utils/Initializable.sol";
import "../../blast/GasManagerable.sol";
import "../../vault/interfaces/IOutETHVault.sol";

/**
 * @title Outrun ETH Wrapped Token
 */
contract RETH is IRETH, ERC20, Initializable, Ownable, GasManagerable {
    address private _outETHVault;

    modifier onlyOutETHVault() {
        if (msg.sender != _outETHVault) {
            revert PermissionDenied();
        }
        _;
    }

    constructor(address owner, address gasManager) ERC20("Outrun Wrapped ETH", "RETH") Ownable(owner) GasManagerable(gasManager) {}

    function outETHVault() external view override returns (address) {
        return _outETHVault;
    }

    /**
     * @dev Initializer
     * @param _vault - Address of OutETHVault
     */
    function initialize(address _vault) external override initializer {
        setOutETHVault(_vault);
    }

    /**
     * @dev Allows user to deposit ETH and mint RETH
     */
    function deposit() public payable override {
        uint256 amount = msg.value;
        if (amount == 0) {
            revert ZeroInput();
        }

        address user = msg.sender;
        Address.sendValue(payable(_outETHVault), amount);
        _mint(user, amount);

        emit Deposit(user, amount);
    }

    /**
     * @dev Allows user to withdraw ETH by RETH
     * @param amount - Amount of RETH for burn
     */
    function withdraw(uint256 amount) external override {
        if (amount == 0) {
            revert ZeroInput();
        }
        address user = msg.sender;
        _burn(user, amount);
        IOutETHVault(_outETHVault).withdraw(user, amount);

        emit Withdraw(user, amount);
    }

    /**
     * @dev OutETHVault fee
     */
    function mint(address _account, uint256 _amount) external override onlyOutETHVault {
        _mint(_account, _amount);
    }

    function setOutETHVault(address _vault) public override onlyOwner {
        _outETHVault = _vault;
        emit SetOutETHVault(_vault);
    }

    receive() external payable {
        deposit();
    }
}