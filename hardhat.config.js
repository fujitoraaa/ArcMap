import "dotenv/config";
import "@nomicfoundation/hardhat-toolbox";

/** @type import('hardhat/config').HardhatUserConfig */
const config = {
  solidity: {
    version: "0.8.24",
    settings: {
      viaIR: true, 
      optimizer: {
        enabled: true,
        runs: 200
      },
      evmVersion: "cancun"
    }
  },
  networks: {
    arcTestnet: {
      url: "https://rpc.blockdaemon.testnet.arc.network", // Vẫn ưu tiên WebSocket nếu có thể
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      chainId: 5042002,
      timeout: 100000,
      gasPrice: "auto", 
    }
  }
};

export default config;