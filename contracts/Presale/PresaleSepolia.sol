// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Presale} from "./Presale.sol";

contract PresaleSepolia is Presale {
    address public constant USDT = 0x56f36B6B1F6D69f1355070be1e5452329abE2326;
    address public constant USDC = 0x772a437F10E1CFb9C8186d4DFAa278eC97BE30b1;
    address public constant DAI = 0xC66EfC95A9BF5C724b62236Ac85FDBB9C091c83e;

    uint256 public priceUSDT;
    uint256 public priceUSDC;
    uint256 public priceDAI;

    constructor(address sage, address staking) Presale(sage, staking) {}

    function setPrice(
        uint256 newPriceUsdt,
        uint256 newPriceUsdc,
        uint256 newPriceDai
    ) external onlyOwner {
        (priceUSDT, priceUSDC, priceDAI) = (
            newPriceUsdt,
            newPriceUsdc,
            newPriceDai
        );
    }

    function buyForUSDT(uint256 amount) external {
        _buy(amount, USDT, priceUSDT);
    }

    function buyForUSDC(uint256 amount) external {
        _buy(amount, USDC, priceUSDC);
    }

    function buyForDAI(uint256 amount) external {
        _buy(amount, DAI, priceDAI);
    }
}
