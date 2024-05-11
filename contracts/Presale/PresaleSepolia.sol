// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Presale} from "./Presale.sol";

contract PresaleSepolia is Presale {
    address public constant USDT = 0x538Ff108B92Cf77f2A67f3f8BBb1f614729190C2;
    address public constant USDC = 0x27C43E8C9c7A9521cd7747D86fb9b439e0A1917F;
    address public constant DAI = 0xaF1093b9038a1CF8f3a75Db3d8C419E9bb710F30;

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
