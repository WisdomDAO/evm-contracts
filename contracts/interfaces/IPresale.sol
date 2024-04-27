// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPresale {
    event Buy(address indexed buyer, uint256 amount, address token);
    event Claim(address indexed buyer, uint256 amount);
    event Stop(uint48 stakingStartsAt);

    error ZeroAddress();
    error AmountTooLow();
    error NotEnoughSAGE();
    error AlreadyClaimed();
    error BadSignature();
    error PresaleEnded();
    error ZeroAmount();
}