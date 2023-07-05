require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "fantom",
  networks: {
    fantom: {
      url: `https://rpc.testnet.fantom.network`,
      chainId: 4002,
      accounts: [
        process.env.ACCOUNT2,
        process.env.ACCOUNT3,
        process.env.ACCOUNT1,
      ],
    },
    moom: {
      url: `https://rpc.api.moonbase.moonbeam.network`,
      chainId: 1287,
      accounts: [
        process.env.ACCOUNT2,
        process.env.ACCOUNT1,
        process.env.ACCOUNT3,
      ],
    },

    zen: {
      chainId: 1663,
      url: process.env.HORIZEN_RPC_URL,
      accounts: [
        process.env.ACCOUNT1,
        process.env.ACCOUNT2,
        process.env.ACCOUNT3,
      ],
      gasPrice: "auto",
    },
    Fmainnet: {
      url: `https://rpcapi.fantom.network`,
      chainId: 250,
      accounts: [
        process.env.ACCOUNT1,
        process.env.ACCOUNT2,
        process.env.ACCOUNT3,
      ],
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL,
      accounts: [
        process.env.ACCOUNT2,
        process.env.ACCOUNT1,
        process.env.ACCOUNT3,
        process.env.ACCOUNT4,
      ],
    },
    calibrationnet: {
      chainId: 314159,
      url: process.env.CALIBRATIONNET_RPC_URL,
      accounts: [
        process.env.ACCOUNT2,
        process.env.ACCOUNT1,
        process.env.ACCOUNT3,
        process.env.ACCOUNT4,
      ],
    },
  },
};
