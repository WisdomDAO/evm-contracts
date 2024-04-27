// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC20Taxable.sol";

/**
 * @title ERC20 Taxable Token
 * @author https://wisdomdao.finance
 * @notice SAGE token by the Wisdom DAO
 */
abstract contract ERC20Taxable is ERC20, IERC20Taxable {
    /// @dev Maximal buy and sell tax percentage
    uint16 private constant MAX_TAX = 500;

    /// @notice Buy tax (1 = 0.01%)
    uint16 public taxIn = 500;

    /// @notice Sell tax (1 = 0.01%)
    uint16 public taxOut = 500;

    /// @dev Wisdom DAO Treasure address
    address public treasury;

    /// @notice Is contract perform swap operations with SAGE token?
    mapping(address => bool) public taxable;

    /// @notice Is address is untaxable?
    mapping(address => bool) public untaxable;

    /// @dev Allow function call for Treasury only
    modifier onlyTreasury() {
        if (msg.sender != treasury) revert OnlyTreasuryCanCallThisFunction();
        _;
    }

    /**
     * @dev token deployment
     * @param initialDistributor Deployer address
     */
    constructor(address initialDistributor) {
        if (initialDistributor == address(0)) initialDistributor = msg.sender;
        untaxable[initialDistributor] = true;
        treasury = initialDistributor;
    }

    /**
     * @notice Change Wisdom DAO Treasury contract
     * @param newTreasury Address of the new Wisdom DAO Treasury contract
     * @dev Only current treasury can execute this action.
     */
    function setTreasury(address newTreasury) external virtual onlyTreasury {
        if (newTreasury == address(0)) revert ZeroAddress();
        untaxable[newTreasury] = true;
        treasury = newTreasury;
        emit NewTreasury(newTreasury);
    }

    /**
     * @notice Change buy/sell taxes
     * @param newTaxIn Buy tax amount
     * @param newTaxOut Sell tax amount
     * @dev Maximal tax amount is 5% (500).
     */
    function setTaxes(
        uint16 newTaxIn,
        uint16 newTaxOut
    ) external virtual onlyTreasury {
        if (newTaxIn > MAX_TAX || newTaxOut > MAX_TAX) revert AmountTooBig();
        (taxIn, taxOut) = (newTaxIn, newTaxOut);
        emit TaxesChanged(newTaxIn, newTaxOut);
    }

    /**
     * @notice Set tax on swaps
     * @param poolAddress Address of the swap contract
     * @param isTaxable Is poolAddress is taxable?
     */
    function setTaxable(
        address poolAddress,
        bool isTaxable
    ) external virtual onlyTreasury {
        if (poolAddress == address(0)) revert ZeroAddress();
        taxable[poolAddress] = isTaxable;
        emit Taxable(poolAddress, isTaxable);
    }

    /**
     * @notice Make address untaxable.
     * @param untaxableAddress EOA or contract address
     * @param isUntaxable Is address untaxable?
     */
    function setUntaxable(
        address untaxableAddress,
        bool isUntaxable
    ) external virtual onlyTreasury {
        if (untaxableAddress == address(0)) revert ZeroAddress();
        untaxable[untaxableAddress] = isUntaxable;
        emit Untaxable(untaxableAddress, isUntaxable);
    }

    /**
     * @notice Estimate transaction taxes
     * @param from Sender address
     * @param to Receiver address
     * @param value Token amount
     * @return taxedValue Value after taxes
     * @return taxAmount Tax amount
     * @return taxMultiplier Used multiplier
     * @return taxPayer Who will pay taxes for this tx?
     */
    function calcTaxes(
        address from,
        address to,
        uint256 value
    )
        public
        view
        virtual
        returns (
            uint256 taxedValue,
            uint256 taxAmount,
            uint256 taxMultiplier,
            address taxPayer
        )
    {
        (taxMultiplier, taxPayer) = taxable[from]
            ? (taxIn, to)
            : (taxOut, from);
        taxAmount = (value * taxMultiplier) / 1e4;
        taxedValue = value - taxAmount;
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
    ) internal virtual override(ERC20) {
        if (taxable[to]) value = _chargeTaxes(from, to, value);
        super._update(from, to, value);
        if (taxable[from]) _chargeTaxes(from, to, value);
    }

    /**
     * @dev Check taxpayer and transfer taxes if needed
     * @param from Token sender
     * @param to Token receiver
     * @param value Amount of token sent
     * @return Value after taxes
     */
    function _chargeTaxes(
        address from,
        address to,
        uint256 value
    ) internal virtual returns (uint256) {
        if (
            (taxable[from] || taxable[to]) &&
            (!untaxable[from] && !untaxable[to]) &&
            !(taxable[from] && taxable[to]) // prevent double taxes
        ) {
            (
                uint256 taxedValue,
                uint256 taxAmount,
                ,
                address taxPayer
            ) = calcTaxes(from, to, value);
            _transfer(taxPayer, treasury, taxAmount);

            return taxedValue;
        }

        return value;
    }
}
