// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Taxable is IERC20 {
    event Taxable(address poolAddress, bool isTaxable);
    event Untaxable(address user, bool isUntaxable);
    event NewTreasury(address newTreasury);
    event TaxesChanged(uint16 taxIn, uint16 taxOut);
    event Tax(uint256 taxAmount);

    error OnlyTreasuryCanCallThisFunction();
    error AmountTooBig();
    error ZeroAddress();

    function setTreasury(address newTreasury) external;

    function setTaxes(uint16 newTaxIn, uint16 newTaxOut) external;

    function setTaxable(address poolAddress, bool isTaxable) external;

    function setUntaxable(address userAddress, bool isUntaxable) external;

    function calcTaxes(
        address from,
        address to,
        uint256 value
    )
        external
        view
        returns (
            uint256 taxedValue,
            uint256 taxAmount,
            uint256 taxMultiplier,
            address taxPayer
        );
}
