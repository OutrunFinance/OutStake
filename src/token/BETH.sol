// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./interfaces/IBETH.sol";
import "../vault/interfaces/IBnETHVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Bang ETH Wrapped Token
 */
contract BETH is IBETH, ERC20, Ownable {
    address public BnETHVault;

    modifier onlyBnETHVault() {
        require(msg.sender == BnETHVault, "Access only by BnETHVault");
        _;
    }

    constructor(address owner, address _BnETHVault) ERC20("Bang Wrapped ETH", "BETH") Ownable(owner) {
        require(_BnETHVault != address(0), "Zero address provided");

        BnETHVault = _BnETHVault;

        emit SetBnETHVault(_BnETHVault);
    }

    function deposit() public payable override {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid Amount");

        address user = msg.sender;
        Address.sendValue(payable(BnETHVault), amount);
        _mint(user, amount);

        emit Deposit(user, amount);
    }

    function withdraw(uint256 amount) external override {
        require(amount > 0, "Invalid Amount");

        address user = msg.sender;
        _burn(user, amount);
        IBnETHVault(BnETHVault).withdraw(msg.sender, amount);

        emit Withdraw(user, amount);
    }

    function mint(address _account, uint256 _amount) external override onlyBnETHVault {
        _mint(_account, _amount);
    }

    function setBnETHVault(address _BnETHVault) external override onlyOwner {
        require(_BnETHVault != address(0), "Zero address provided");

        BnETHVault = _BnETHVault;

        emit SetBnETHVault(_BnETHVault);
    }

    receive() external payable {
        deposit();
    }
}