var ERC1538Delegate = artifacts.require("ERC1538Delegate");
var Router = artifacts.require("Router");

module.exports = async function(deployer) {
  deployer.deploy(ERC1538Delegate).then(function() {
    return deployer.deploy(Router, ERC1538Delegate.address, {
      value: web3.toWei(1)
    });
  });
};
