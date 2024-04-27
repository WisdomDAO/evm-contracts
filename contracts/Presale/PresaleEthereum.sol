// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Presale} from "./Presale.sol";

contract PresaleEthereum is Presale {
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

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
