// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.26;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import "../common/OutrunOFT.sol";
import "./interfaces/IPrincipalToken.sol";

contract OutrunOmnichainUniversalPrincipalToken is IPrincipalToken, OutrunOFT {
    mapping(address authContract => bool) public authList;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address _lzEndpoint,
        address _delegate
    ) OutrunOFT(name_, symbol_, decimals_, _lzEndpoint, _delegate) Ownable(_delegate) {}

    modifier onlyAuthList() {
        require(authList[msg.sender], PermissionDenied());
        _;
    }

    /**
     * @param authContract - Address of auth contract
     * @param authorized - Authorization status
     */
    function setAuthList(address authContract, bool authorized) external override onlyOwner {
        authList[authContract] = authorized;
    }

    /**
     * @dev Only auth contract can mint when the user stake native yield token
     * @param account Address who receive PT 
     * @param amount The amount of minted PT
     */
    function mint(address account, uint256 amount) external override onlyAuthList {
        _mint(account, amount);
    }

    /**
     * @dev Only auth contract can burn when the user redempt the native yield token 
     * @param account Address who burn PT
     * @param amount The amount of burned PT
     */
    function burn(address account, uint256 amount) external override onlyAuthList {
        _burn(account, amount);
    }
}
