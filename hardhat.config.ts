import '@nomicfoundation/hardhat-chai-matchers';
import '@nomicfoundation/hardhat-verify';
import "@nomiclabs/hardhat-etherscan";

import env from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';

env.config();

const config: HardhatUserConfig | any = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000,
          },
        },
      },
      {
        version: "0.5.16",
        settings: {},
      },
      {
        version: "0.6.6",
        settings: {},
      },
    ],
  },
  networks: {
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: [process.env.PRIVATE_KEY_1]
    },
    mainnet: {
      url: "https://eth.llamarpc.com",
      accounts: [process.env.PRIVATE_KEY_1]
    },
    bionicTestnet: {
      url: "http://testnet.bionicecosystem.io",
      accounts: [process.env.PRIVATE_KEY_2]
    }
  },
  etherscan: {
    apiKey: {
        goerli: "9NN63CI398KJR3IIPCVMTF5IQD5AKJRMJI",
        mainnet: "9NN63CI398KJR3IIPCVMTF5IQD5AKJRMJI",
        bionicTestnet: "9NN63CI398KJR3IIPCVMTF5IQD5AKJRMJI",
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
      },
      {
        network: "bionicTestnet",
        chainId: 256127,
        urls: {
          apiURL: "https://explorer-backend-testnet.bionicecosystem.io/api",
          browserURL: "https://explorer-testnet.bionicecosystem.io"
        }
      }
    ]
  }
};

export default config;
