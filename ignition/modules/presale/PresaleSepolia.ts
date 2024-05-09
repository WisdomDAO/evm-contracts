import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import SageModule from "../Sage";
import StakingModule from "../Staking";

const PresaleSepoliaModule = buildModule("PresaleSepoliaModule", (m) => {
  const { sage } = m.useModule(SageModule);
  const { staking } = m.useModule(StakingModule);
  const presale = m.contract("PresaleSepolia", [sage, staking]);

  return { presale };
});

export default PresaleSepoliaModule;
