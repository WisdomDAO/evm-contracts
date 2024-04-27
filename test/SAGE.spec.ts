import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import { ethers } from "hardhat";
import { SAGE } from "../typechain-types";

const TOTAL_SUPPLY = 10_000_000n * BigInt(1e18);
const ONE_TOKEN = BigInt(1e18);
const TAX = 500n;
const DELIMITER = 10000n;
const DECIMALS = 18n;

const OnlyTreasuryCanCallThisFunction = "OnlyTreasuryCanCallThisFunction";
const AmountTooBig = "AmountTooBig";
const ZeroAddress = "ZeroAddress";

const balanceAfterTax = (value: bigint) => value - tax(value);
const tax = (value: bigint) => (value * TAX) / DELIMITER;

describe("SAGE", function () {
  async function deploySageFixture() {
    const [owner, treasury, pool, user1, user2, untaxable] =
      await hre.ethers.getSigners();

    const Sage = await hre.ethers.getContractFactory("SAGE");
    const sage = await Sage.deploy(treasury.address);

    await sage.connect(treasury).transfer(pool.address, ONE_TOKEN);
    await sage.connect(treasury).setTaxable(pool.address, true);
    await sage.connect(treasury).setUntaxable(untaxable.address, true);
    await sage.connect(treasury).transfer(user1.address, ONE_TOKEN * 100n);

    return { owner, treasury, pool, user1, user2, untaxable, sage };
  }

  describe("Deployment", function () {
    it("Should be correctly deployed without treasury address", async () => {
      const { owner } = await loadFixture(deploySageFixture);

      const Sage = await hre.ethers.getContractFactory("SAGE");
      const sage: SAGE = await Sage.deploy(ethers.ZeroAddress);

      expect(await sage.treasury()).to.equal(owner.address);
      expect(await sage.name()).to.be.equal("Wisdom DAO");
      expect(await sage.symbol()).to.be.equal("SAGE");
      expect(await sage.decimals()).to.be.equal(DECIMALS);
      expect(await sage.totalSupply()).to.be.equal(TOTAL_SUPPLY);
      expect(await sage.balanceOf(owner.address)).to.be.equal(TOTAL_SUPPLY);
      expect(await sage.taxIn()).to.be.equal(TAX);
      expect(await sage.taxOut()).to.be.equal(TAX);
      expect(await sage.untaxable(owner.address)).to.equal(true);
    });

    it("Should be burnable", async () => {
      const { sage, user1 } = await loadFixture(deploySageFixture);

      await sage.connect(user1).burn(ONE_TOKEN)
      expect(await sage.balanceOf(user1.address)).to.be.equal(ONE_TOKEN * 99n);
    });
  });

  describe("Tax system", function () {
    it("Regular transactions shouldn't be taxed", async () => {
      const { sage, user1, user2 } = await loadFixture(deploySageFixture);

      await sage.connect(user1).transfer(user2.address, ONE_TOKEN);

      expect(await sage.balanceOf(user1)).to.equal(ONE_TOKEN * 99n);
      expect(await sage.balanceOf(user2)).to.equal(ONE_TOKEN);
    });

    it("Sell swaps should be taxed", async () => {
      const { sage, user1, pool } = await loadFixture(deploySageFixture);

      await sage.connect(user1).transfer(pool.address, ONE_TOKEN);

      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN * 99n);
      expect(await sage.balanceOf(pool.address)).to.equal(
        balanceAfterTax(ONE_TOKEN) + ONE_TOKEN
      );
    });

    it("Buy swaps should be taxed", async () => {
      const { sage, user2, pool } = await loadFixture(deploySageFixture);

      await sage.connect(pool).transfer(user2.address, ONE_TOKEN);

      expect(await sage.balanceOf(user2.address)).to.equal(
        balanceAfterTax(ONE_TOKEN)
      );
      expect(await sage.balanceOf(pool.address)).to.equal(0);
    });

    it("Sell swaps shouldn't be taxed for untaxable address", async () => {
      const { sage, untaxable, pool, treasury } = await loadFixture(
        deploySageFixture
      );

      await sage.connect(treasury).transfer(untaxable, ONE_TOKEN);
      await sage.connect(untaxable).transfer(pool.address, ONE_TOKEN);

      expect(await sage.balanceOf(untaxable.address)).to.equal(0);
      expect(await sage.balanceOf(pool.address)).to.equal(ONE_TOKEN * 2n);
    });

    it("Buy swaps shouldn't be taxed for untaxable address", async () => {
      const { sage, untaxable, pool } = await loadFixture(deploySageFixture);

      await sage.connect(pool).transfer(untaxable.address, ONE_TOKEN);

      expect(await sage.balanceOf(untaxable.address)).to.equal(ONE_TOKEN);
      expect(await sage.balanceOf(pool.address)).to.equal(0);
    });

    it("Should set treasury", async () => {
      const { sage, user1, treasury } = await loadFixture(
        deploySageFixture
      );

      await expect(sage.setTreasury(user1)).to.be.revertedWithCustomError(
        sage,
        OnlyTreasuryCanCallThisFunction
      );
      await expect(
        sage.connect(treasury).setTreasury(ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(sage, ZeroAddress);
      await sage.connect(treasury).setTreasury(user1);

      expect(await sage.treasury()).to.be.equal(user1.address);
    });

    it("Should set tax rates", async () => {
      const { sage, treasury } = await loadFixture(
        deploySageFixture
      );

      await expect(sage.setTaxes(100n, 100n)).to.be.revertedWithCustomError(
        sage,
        OnlyTreasuryCanCallThisFunction
      );
      await expect(sage.connect(treasury).setTaxes(100n, 100n))
        .to.emit(sage, "TaxesChanged")
        .withArgs(100n, 100n);
      await expect(
        sage.connect(treasury).setTaxes(501n, 100n)
      ).to.be.revertedWithCustomError(sage, AmountTooBig);
      await expect(
        sage.connect(treasury).setTaxes(100n, 501n)
      ).to.be.revertedWithCustomError(sage, AmountTooBig);

      expect(await sage.taxIn()).to.be.equal(100n);
      expect(await sage.taxOut()).to.be.equal(100n);
    });

    it("Should check taxable and untaxable params", async () => {
      const { sage, user1, treasury } = await loadFixture(
        deploySageFixture
      );

      await expect(sage.setTaxable(user1, true)).to.be.revertedWithCustomError(
        sage,
        OnlyTreasuryCanCallThisFunction
      );
      await expect(sage.setUntaxable(user1, true)).to.be.revertedWithCustomError(
        sage,
        OnlyTreasuryCanCallThisFunction
      );
      await expect(
        sage.connect(treasury).setTaxable(ethers.ZeroAddress, true)
      ).to.be.revertedWithCustomError(sage, ZeroAddress);
      await expect(
        sage.connect(treasury).setUntaxable(ethers.ZeroAddress, true)
      ).to.be.revertedWithCustomError(sage, ZeroAddress);
    })
  });
});
