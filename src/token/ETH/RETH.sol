// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IRETH.sol";
import "../../vault/interfaces/IOutETHVault.sol";

/**
 * @title Outrun ETH Wrapped Token
 */
contract RETH is IRETH, ERC20, Ownable {
    address public outETHVault;

    modifier onlyOutETHVault() {
        require(msg.sender == outETHVault, "Access only by outETHVault");
        _;
    }

    constructor(address owner) ERC20("Outrun Wrapped ETH", "RETH") Ownable(owner) {}

    /**
     * @dev Allows user to deposit ETH and mint RETH
     */
    function deposit() public payable override {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");

        address user = msg.sender;
        Address.sendValue(payable(outETHVault), amount);
        _mint(user, amount);

        emit Deposit(user, amount);
    }

    /**
     * @dev Allows user to withdraw ETH by RETH
     * @param amount - Amount of RETH for burn
     */
    function withdraw(uint256 amount) external override {
        require(amount > 0, "Invalid Amount");
        address user = msg.sender;
        _burn(user, amount);
        IOutETHVault(outETHVault).withdraw(user, amount);

        emit Withdraw(user, amount);
    }

    function mint(address _account, uint256 _amount) external override onlyOutETHVault {
        _mint(_account, _amount);
    }

    function setOutETHVault(address _outETHVault) external override onlyOwner {
        outETHVault = _outETHVault;
        emit SetOutETHVault(_outETHVault);
    }

    receive() external payable {
        deposit();
    }
}