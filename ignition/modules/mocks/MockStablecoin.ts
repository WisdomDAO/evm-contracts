import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MockStablesModule = buildModule("MockStablesModule", (m) => {
  const usdt = m.contract("MockStablecoin", ["Mock Tether", "MUSDT", 6], { id: "USDT"});
  const usdc = m.contract("MockStablecoin", ["Mock Circle", "MUSDC", 6], { id: "USDC"});
  const dai = m.contract("MockStablecoin", ["Mock DAI", "MDAI", 18], { id: "DAI"});

  return { usdt, usdc, dai };
});

export default MockStablesModule;
