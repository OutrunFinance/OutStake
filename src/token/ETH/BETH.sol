// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IBETH.sol";
import "../../vault/interfaces/IBnETHVault.sol";
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
        BnETHVault = _BnETHVault;
        emit SetBnETHVault(_BnETHVault);
    }

    function mint(address _account, uint256 _amount) external override onlyBnETHVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyBnETHVault {
        _burn(_account, _amount);
    }

    function setBnETHVault(address _BnETHVault) external override onlyOwner {
        BnETHVault = _BnETHVault;
        emit SetBnETHVault(_BnETHVault);
    }
}