// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20Taxable} from "./IERC20Taxable.sol";

interface ISAGE is IERC20, IERC20Taxable, IERC20Permit {
    /**
     * @notice You can burn some amount of your SAGE tokens
     * @param amount Amount of SAGE tokens to burn
     */
    function burn(uint256 amount) external;
}
