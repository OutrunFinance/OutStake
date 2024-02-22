// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import "./interfaces/IRUSD.sol";
import "../../vault/interfaces/IOutUSDBVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Outrun USD Wrapped Token
 */
contract RUSD is IRUSD, ERC20, Ownable {
    address public outUSDBVault;

    modifier onlyOutUSDBVault() {
        require(msg.sender == outUSDBVault, "Access only by OutUSDBVault");
        _;
    }

    constructor(address owner) ERC20("Outrun Wrapped USDB", "RUSD") Ownable(owner) {}

    function mint(address _account, uint256 _amount) external override onlyOutUSDBVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyOutUSDBVault {
        _burn(_account, _amount);
    }

    function setOutUSDBVault(address _outUSDBVault) external override onlyOwner {
        outUSDBVault = _outUSDBVault;
        emit SetOutUSDBVault(_outUSDBVault);
    }
}