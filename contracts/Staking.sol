// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {IPresale} from "./interfaces/IPresale.sol";

contract Staking is Ownable, IStaking {
    /// OpenZeppelin's lib for safe token transfers
    using SafeERC20 for IERC20;

    /// @notice SAGE token address
    address public immutable sage;

    /// @notice Duration in blocks
    uint128 public immutable duration;

    /// @notice Staking starts at block
    uint128 public startAtBlock;

    /// @notice Balance of user
    mapping(address => uint256) public balanceOf;

    /// @notice Previous claim
    mapping(address => uint256) public lastClaimAtBlock;

    /// @dev Allow to execute functions with this modifier when staking begins
    modifier isStarted() {
        if (startAtBlock > block.number) revert NotStartedYet();
        _;
    }

    /// @dev Create staking contract
    constructor(
        address sageTokenAddress,
        uint64 stakingDurationInBlocks
    ) Ownable(msg.sender) {
        sage = sageTokenAddress;
        duration = stakingDurationInBlocks;
    }

    /**
     * @notice Add buyer to the staking contract
     * @param user Buyer of the token on public presale
     * @param amount Amount of the SAGE tokens user bought
     * @dev Owner (presale contract) should have 2 * amount SAGE tokens on the 
     * balance. Owner can add users before staking starts. After start ownership
     * of this contract will be renounced.
     */
    function add(address user, uint256 amount) external onlyOwner() {
        // Transfer bought and staking rewards
        IERC20(sage).safeTransferFrom(owner(), address(this), amount * 2);
        balanceOf[user] += amount;
    }

    /**
     * @notice Start staking
     * @param blockNumber Number of the block from staking beginnings
     * @dev This function can be executed by owner (presale contract) only once,
     * after that ownership of this contract will be renounced.
     */
    function start(uint128 blockNumber) external onlyOwner() {
        // Check blockNumber
        if (blockNumber == 0) revert ZeroAmount();
        // Set block number when staking begins
        startAtBlock = blockNumber;
        // Renounce ownership. This contract has no owner anymore.
        renounceOwnership();
    }

    function withdraw() external isStarted {
        if (balanceOf[msg.sender] == 0) revert ZeroAmount();

        // Withdraw tokens
        uint256 balance = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        IERC20(sage).safeTransfer(msg.sender, balance);

        // Burn unclaimed tokens
        uint256 unclaimed = 
            balance * (finalBlock() - _getLastClaim(msg.sender)) / duration;
        if (unclaimed != 0) IERC20(sage).safeTransfer(address(0), unclaimed);

        emit Withdraw(msg.sender, balance, unclaimed);
    }

    function claim() external isStarted {
        if (lastClaimAtBlock[msg.sender] == block.number) revert AlreadyClaimed();
        uint256 amount = claimableAmount(msg.sender);
        if (amount == 0) revert ZeroAmount();
        lastClaimAtBlock[msg.sender] = block.number;
        IERC20(sage).safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function claimableAmount(address user) public view returns (uint256) {
        if (startAtBlock >= block.number || balanceOf[user] == 0) return 0;
        uint256 previousClaimAt = _getLastClaim(user);
        uint256 lastBlock = block.number <= finalBlock()
            ? block.number
            : finalBlock();

        return balanceOf[user] * (lastBlock - previousClaimAt) / duration;
    }

    function finalBlock() public view returns (uint256) {
        return duration + startAtBlock;
    }

    function _getLastClaim(address user) internal view returns (uint256) {
        return lastClaimAtBlock[user] == 0 ? startAtBlock : lastClaimAtBlock[user];
    }
}
