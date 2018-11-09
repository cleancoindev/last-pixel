const HDWalletProvider = require("truffle-hdwallet-provider");
const MNEMONIC = process.env.MNEMONIC
const INFURA_KEY = process.env.INFURA_KEY

if (!MNEMONIC || !INFURA_KEY) {
  console.error("Please set a mnemonic and infura key.")
  return
}

module.exports = {
  networks: {
    development: {
      host:'127.0.0.1',
      port: 8545,
      network_id: '*'
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(
          MNEMONIC,
          "https://rinkeby.infura.io/" + INFURA_KEY
        );
      },
      network_id: "*",
      gas: 4000000
    }
  }
};
