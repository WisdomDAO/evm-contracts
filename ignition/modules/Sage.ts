import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SageModule = buildModule("SageModule", (m) => {
  const owner = m.getParameter("owner", m.getAccount(0));
  const sage = m.contract("SAGE", [owner]);

  return { sage };
});

export default SageModule;
