import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import SageModule from "./Sage";

const StakingModule = buildModule("StakingModule", (m) => {
  const { sage } = m.useModule(SageModule);
  const duration = m.getParameter("duration", 0);
  const staking = m.contract("Staking", [sage, duration]);

  return { staking };
});

export default StakingModule;
