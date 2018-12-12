var Game = artifacts.require("Game");
var GameMock = artifacts.require("GameMock");

module.exports = async function(deployer) {
  deployer.deploy(Game, { gas: 6500000 });
  deployer.deploy(GameMock, {
    gas: 6700000,
    value: web3.toWei(10)
  });
};
