require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    sepolia: {
      url: process.env.RPC_URL_SEPOLIA,
      accounts: [process.env.PK_ACCOUNT_1],
      timeout: 600000,
    },
  },
  solidity: "0.8.19",
};
