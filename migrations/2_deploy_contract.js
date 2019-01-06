var Game = artifacts.require("Game");
var Transparent = artifacts.require("Transparent");
var ERC1538Delegate = artifacts.require("ERC1538Delegate");

module.exports = async function(deployer) {
  deployer.deploy(ERC1538Delegate).then(function() {
    return deployer.deploy(Transparent, ERC1538Delegate.address);
  });
};
