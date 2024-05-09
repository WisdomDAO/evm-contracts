import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'dotenv/config';

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },

  networks: {
    sepolia: {
      url: 'https://rpc.ankr.com/eth_sepolia',
      chainId: 11155111,
      accounts: [process.env.PK as string],
    },
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },

  mocha: {
    timeout: 40000,
  },

  gasReporter: {
    currency: 'EUR',
    coinmarketcap: process.env.CMC_KEY as string,
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API as string,
  },
};

export default config;
