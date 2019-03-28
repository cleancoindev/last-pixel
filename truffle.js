const HDWalletProvider = require("truffle-hdwallet-provider");
const MNEMONIC = process.env.MNEMONIC;
const INFURA_KEY = process.env.INFURA_KEY;

if (!MNEMONIC || !INFURA_KEY) {
  console.error("Please set a mnemonic and infura key.");
  return;
}

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      gas: 4600000,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(
          MNEMONIC,
          "https://rinkeby.infura.io/" + INFURA_KEY
        );
      },
      network_id: "*",
      gasPrice: 5000000000
    },
    live: {
      network_id: 1,
      provider: function() {
        return new HDWalletProvider(
          MNEMONIC,
          "https://mainnet.infura.io/" + INFURA_KEY
        );
      },
      gasPrice: 7000000000
    }
  },
  compilers: {
    solc: {
      version: "0.4.24", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      optimizer: {
        enabled: true,
        runs: 200
      }
      //  evmVersion: "byzantium"
      // }
    }
  }
};
