// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IBUSD.sol";
import "../../vault/interfaces/IBnUSDBVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Bang USD Wrapped Token
 */
contract BUSD is IBUSD, ERC20, Ownable {
    address public BnUSDBVault;

    modifier onlyBnUSDBVault() {
        require(msg.sender == BnUSDBVault, "Access only by BnUSDBVault");
        _;
    }

    constructor(address owner, address _BnUSDBVault) ERC20("Bang Wrapped USDB", "BUSD") Ownable(owner) {
        BnUSDBVault = _BnUSDBVault;
        emit SetBnUSDBVault(_BnUSDBVault);
    }

    function mint(address _account, uint256 _amount) external override onlyBnUSDBVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyBnUSDBVault {
        _burn(_account, _amount);
    }

    function setBnUSDBVault(address _BnUSDBVault) external override onlyOwner {
        BnUSDBVault = _BnUSDBVault;
        emit SetBnUSDBVault(_BnUSDBVault);
    }
}