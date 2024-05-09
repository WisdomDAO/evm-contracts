// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPresale} from "../interfaces/IPresale.sol";
import {IStaking} from "../interfaces/IStaking.sol";

abstract contract Presale is Ownable, IPresale {
    using SafeERC20 for IERC20;

    address public immutable sageToken;
    address public immutable staking;

    uint256 public minAmount = 100e18;
    uint48 public stakingStartsAtBlock;

    mapping(bytes32 => bool) isClaimed;

    modifier checkAmount(uint256 amount) {
        if (amount < minAmount) revert AmountTooLow();
        if (amount > IERC20(sageToken).balanceOf(address(this)))
            revert NotEnoughSAGE();
        if (stakingStartsAtBlock != 0) revert PresaleEnded();
        _;
    }

    constructor(address sage, address stakingContract) Ownable(msg.sender) {
        if (sage == address(0)) revert ZeroAddress();
        if (stakingContract == address(0)) revert ZeroAddress();

        sageToken = sage;
        staking = stakingContract;
        IERC20(sageToken).approve(staking, type(uint256).max);
    }

    function stopPresale(uint48 timestamp) external onlyOwner {
        if (stakingStartsAtBlock != 0) revert PresaleEnded();
        if (timestamp == 0) revert ZeroAmount();

        stakingStartsAtBlock = timestamp;

        uint256 unsold = IERC20(sageToken).balanceOf(address(this));
        if (unsold != 0) IERC20(sageToken).safeTransfer(address(0), unsold);

        IStaking(staking).start(stakingStartsAtBlock);

        emit Stop(stakingStartsAtBlock);
    }

    function claim(
        uint256 amount,
        bytes32 nonce,
        bytes calldata signature
    ) external virtual checkAmount(amount) {
        bytes32 _hash = keccak256(
            abi.encodePacked(amount, nonce, msg.sender, block.chainid)
        );
        if (isClaimed[_hash]) revert AlreadyClaimed();
        if (!SignatureChecker.isValidSignatureNow(owner(), _hash, signature))
            revert BadSignature();
        isClaimed[_hash] = true;
        IERC20(sageToken).safeTransfer(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    function _buy(
        uint256 amount,
        address token,
        uint256 price
    ) internal virtual checkAmount(amount) {
        uint256 _sum = (amount * price) / 1e18;
        IERC20(token).safeTransferFrom(msg.sender, owner(), _sum);
        IStaking(staking).add(msg.sender, amount);

        emit Buy(msg.sender, amount, token);
    }
}
