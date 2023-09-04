import '@nomicfoundation/hardhat-chai-matchers';
import '@nomicfoundation/hardhat-verify';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig | any = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli"
    },
    mainnet: {
      url: "https://eth.llamarpc.com"
    }
  },
  etherscan: {
    apiKey: {
        goerli: "9NN63CI398KJR3IIPCVMTF5IQD5AKJRMJI",
        mainnet: "9NN63CI398KJR3IIPCVMTF5IQD5AKJRMJI",
        optimisticEthereum: "",
        arbitrumOne: "",
    },
    customChains: [
      {
        network: "goerli",
        chainId: 5,
        urls: {
          apiURL: "https://api-goerli.etherscan.io/api",
          browserURL: "https://goerli.etherscan.io"
        }
      },
      {
        network: "mainnet",
        chainId: 1,
        urls: {
          apiURL: "https://api.etherscan.io/api",
          browserURL: "https://etherscan.io"
        }
      }
    ]
  }
};

export default config;
