// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Taxable} from "./IERC20Taxable.sol";

interface ISAGE is IERC20, IERC20Taxable {
}
