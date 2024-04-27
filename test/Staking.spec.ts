import {
  mine,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { MaxUint256 } from "ethers";

const STAKING_DURATION = 7136 * 365 * 3;
const ONE_TOKEN = BigInt(1e18);

const NotStartedYet = "NotStartedYet";
const ZeroAmount = "ZeroAmount";

describe("Presale Staking Program", function () {
  async function deployContracts() {
    const [owner, user1, user2, user3] = await hre.ethers.getSigners();

    const Sage = await hre.ethers.getContractFactory("SAGE");
    const sage = await Sage.deploy(owner.address);

    const Staking = await hre.ethers.getContractFactory("Staking");
    const staking = await Staking.deploy(
      await sage.getAddress(),
      STAKING_DURATION
    );

    return { owner, user1, user2, user3, staking, sage };
  }

  async function deployContractsActivated() {
    const { owner, user1, user2, user3, staking, sage } = await loadFixture(
      deployContracts
    );

    await sage.connect(owner).approve(staking.getAddress(), MaxUint256);
    await staking.connect(owner).add(user1.address, ONE_TOKEN);

    return { owner, user1, user2, user3, staking, sage };
  }

  describe("Claim", function () {
    it("Should be claimable - 10%", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      // Start staking period
      await staking
        .connect(owner)
        .start(await hre.ethers.provider.getBlockNumber());
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) - 1
      );

      // Claim 10%
      await mine(Math.round(STAKING_DURATION / 10) - 2);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(...[user1.address, ONE_TOKEN / 10n]);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN / 10n);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(
        ONE_TOKEN * 2n - ONE_TOKEN / 10n
      );
    });

    it("Should be claimable - 25%", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      // Start staking period
      await staking
        .connect(owner)
        .start(await hre.ethers.provider.getBlockNumber());
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) - 1
      );

      // Claim 25%
      await mine(Math.round(STAKING_DURATION / 4) - 2);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(...[user1.address, ONE_TOKEN / 4n]);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN / 4n);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(
        ONE_TOKEN * 2n - ONE_TOKEN / 4n
      );
    });

    it("Should be claimable - 50%", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      // Start staking period
      await staking
        .connect(owner)
        .start(await hre.ethers.provider.getBlockNumber());
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) - 1
      );

      // Claim 50%
      await mine(Math.round(STAKING_DURATION / 2) - 2);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(...[user1.address, ONE_TOKEN / 2n]);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN / 2n);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(
        ONE_TOKEN * 2n - ONE_TOKEN / 2n
      );
    });

    it("Should be claimable - 0-100%", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      // Start staking period
      await staking
        .connect(owner)
        .start(await hre.ethers.provider.getBlockNumber());
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) - 1
      );

      const quarter = Math.round(STAKING_DURATION / 4);
      const quarterToken = ONE_TOKEN / 4n;

      await mine(quarter - 2);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(user1.address, quarterToken);
      expect(await sage.balanceOf(user1.address)).to.equal(quarterToken);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(
        ONE_TOKEN * 2n - quarterToken
      );

      await mine(quarter - 1);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(user1.address, quarterToken);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN / 2n);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(
        ONE_TOKEN * 2n - ONE_TOKEN / 2n
      );

      await mine(quarter - 1);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(user1.address, quarterToken);
      expect(await sage.balanceOf(user1.address)).to.equal(
        (ONE_TOKEN * 3n) / 4n
      );
      expect(await sage.balanceOf(staking.getAddress())).to.equal(
        ONE_TOKEN * 2n - (ONE_TOKEN * 3n) / 4n
      );

      await mine(quarter - 1);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(user1.address, quarterToken);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(ONE_TOKEN);

      await expect(staking.connect(user1).withdraw())
        .to.emit(staking, "Withdraw")
        .withArgs(user1.address, ONE_TOKEN, 0);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN * 2n);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(0);

      await expect(staking.connect(user1).claim()).to.revertedWithCustomError(
        staking,
        ZeroAmount
      );
    });

    it("Shouldn't be claimable if not started", async () => {
      const { owner, user1, staking } = await loadFixture(
        deployContractsActivated
      );

      await expect(staking.connect(user1).claim()).to.revertedWithCustomError(
        staking,
        "NotStartedYet"
      );

      // Start staking period
      await staking
        .connect(owner)
        .start((await hre.ethers.provider.getBlockNumber()) + 10);
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) + 9
      );

      await expect(staking.connect(user1).claim()).to.revertedWithCustomError(
        staking,
        "NotStartedYet"
      );

      expect(await staking.claimableAmount(user1.address)).to.be.equal(0);
    });
  });

  describe("Withdraw", function () {
    it("Should be withdrawable without bonus", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      await expect(
        staking.connect(user1).withdraw()
      ).to.revertedWithCustomError(staking, NotStartedYet);

      // Start staking period
      await staking
        .connect(owner)
        .start(await hre.ethers.provider.getBlockNumber());
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) - 1
      );

      await expect(staking.connect(user1).withdraw())
        .to.emit(staking, "Withdraw")
        .withArgs(user1.address, ONE_TOKEN, ONE_TOKEN);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(0);

      await expect(
        staking.connect(user1).withdraw()
      ).to.revertedWithCustomError(staking, "ZeroAmount");
    });

    it("Should be withdrawable with 10% bonus", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      // Start staking period
      await staking
        .connect(owner)
        .start(await hre.ethers.provider.getBlockNumber());
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) - 1
      );

      // Claim 10%
      await mine(Math.round(STAKING_DURATION / 10) - 2);
      await expect(staking.connect(user1).claim())
        .to.emit(staking, "Claim")
        .withArgs(...[user1.address, ONE_TOKEN / 10n]);
      expect(await sage.balanceOf(user1.address)).to.equal(ONE_TOKEN / 10n);
      expect(await sage.balanceOf(staking.getAddress())).to.equal(
        ONE_TOKEN * 2n - ONE_TOKEN / 10n
      );

      await expect(staking.connect(user1).withdraw())
        .to.emit(staking, "Withdraw")
        .withArgs(user1.address, ONE_TOKEN, ONE_TOKEN - ONE_TOKEN / 10n);
      expect(await sage.balanceOf(user1.address)).to.equal(
        (ONE_TOKEN * 11n) / 10n
      );
      expect(await sage.balanceOf(staking.getAddress())).to.equal(0);
    });
  });

  describe("Misc", function () {
    it("Check restricted methods", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      await sage.connect(owner).transfer(user1.address, ONE_TOKEN);
      await expect(staking.connect(user1).add(user1.address, ONE_TOKEN))
        .to.be.revertedWithCustomError(staking, "OwnableUnauthorizedAccount")
        .withArgs(user1.address);

      await sage.connect(owner).transfer(user1.address, ONE_TOKEN);
      await expect(staking.connect(user1).start(STAKING_DURATION))
        .to.be.revertedWithCustomError(staking, "OwnableUnauthorizedAccount")
        .withArgs(user1.address);

      await expect(
        staking.connect(owner).start(0)
      ).to.be.revertedWithCustomError(staking, ZeroAmount);
    });

    it("Shouldn't be claimable in same block", async () => {
      const { owner, user1, staking, sage } = await loadFixture(
        deployContractsActivated
      );

      await staking
        .connect(owner)
        .start(await hre.ethers.provider.getBlockNumber());
      expect(await staking.startAtBlock()).to.be.equal(
        (await hre.ethers.provider.getBlockNumber()) - 1
      );

      // Claim 10%
      await mine(Math.round(STAKING_DURATION / 10) - 2);
      console.log(await hre.network.provider.send("evm_setAutomine", [false]));
      await staking.connect(user1).claim();
      console.log(await hre.ethers.provider.getBlockNumber())
      await staking.connect(user1).claim();
      console.log(await hre.ethers.provider.getBlockNumber())
      await staking.connect(user1).claim();
      console.log(await hre.ethers.provider.getBlockNumber())
      // await hre.network.provider.send("evm_setAutomine", [true]);
      await expect(staking.connect(user1).claim()).to.revertedWithCustomError(
        staking,
        "AlreadyClaimed"
      );
    });
  });
});
