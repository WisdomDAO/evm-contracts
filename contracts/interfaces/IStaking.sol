// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStaking {
    event Claim(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 burned);

    error NotStartedYet();
    error ZeroAmount();
    error AlreadyClaimed();

    function add(address user, uint256 amount) external;
    function start(uint128 blockNumber) external;
    function withdraw() external;
    function claim() external;
    function claimableAmount(address user) external view returns (uint256);
    function finalBlock() external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
    function lastClaimAtBlock(address user) external view returns (uint256);
}
