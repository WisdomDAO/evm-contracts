// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./Token/ERC20Taxable.sol";
import "./interfaces/ISage.sol";

/**
 * @title SAGE token contract
 * @author https://wisdomdao.finance
 * @notice SAGE token by the Wisdom DAO
 */
contract SAGE is ERC20, ERC20Taxable, ERC20Permit, ERC20Votes, ISAGE {
    /**
     * @dev token deployment
     * @param initialDistributor Deployer address
     */
    constructor(
        address initialDistributor
    )
        ERC20("Wisdom DAO", "SAGE")
        ERC20Permit("Wisdom DAO")
        ERC20Taxable(initialDistributor)
    {
        if (initialDistributor == address(0)) initialDistributor = msg.sender;
        _mint(initialDistributor, 10000000 * 10 ** decimals());
    }

    /**
     * @notice You can burn some amount of your SAGE tokens
     * @param amount Amount of SAGE tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Implemented gas efficient taxability
     * @param from Sender address
     * @param to Receiver address
     * @param value Token amount
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes, ERC20Taxable) {
        super._update(from, to, value);
    }

    /**
     * @dev Overrides for ERC20Permit
     * @param owner Address
     */
    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
