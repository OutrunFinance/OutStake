// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./interfaces/IRETH.sol";
import "../../vault/interfaces/IOutETHVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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

    function mint(address _account, uint256 _amount) external override onlyOutETHVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyOutETHVault {
        _burn(_account, _amount);
    }

    function setOutETHVault(address _outETHVault) external override onlyOwner {
        outETHVault = _outETHVault;
        emit SetOutETHVault(_outETHVault);
    }
}