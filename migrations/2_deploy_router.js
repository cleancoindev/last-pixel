var ERC1538Delegate = artifacts.require("ERC1538Delegate");
var Router = artifacts.require("Router");
const PIXEL_CONTRACT_ADDRESS = process.env.PIXEL_CONTRACT_ADDRESS;
const COLOR_CONTRACT_ADDRESS = process.env.COLOR_CONTRACT_ADDRESS;

module.exports = async function(deployer) {
  deployer.deploy(ERC1538Delegate).then(function() {
    return deployer.deploy(Router, ERC1538Delegate.address, {
      value: web3.toWei("0.2") //for tests to run easily
    });
  });
};
