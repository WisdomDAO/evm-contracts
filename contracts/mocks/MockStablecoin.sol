// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MockStablecoin is ERC20, ERC20Permit {
    uint8 private immutable _decimals;

    constructor(
        string memory tokenName, 
        string memory tokenSymbol, 
        uint8 tokenDecimals
    )
        ERC20(tokenName, tokenSymbol)
        ERC20Permit(tokenName)
    {
        _decimals = tokenDecimals;
        mint();
    }

    function mint() public {
        _mint(msg.sender, 1_000_000 * 10 ** _decimals);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}