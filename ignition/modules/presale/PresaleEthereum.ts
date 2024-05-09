import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import SageModule from "../Sage";
import StakingModule from "../Staking";

const PresaleEthereumModule = buildModule("PresaleEthereumModule", (m) => {
  const sage = m.useModule(SageModule);
  const staking = m.useModule(StakingModule);
  const presale = m.contract("PresaleEthereum", [sage, staking]);

  return { presale };
});

export default PresaleEthereumModule;
