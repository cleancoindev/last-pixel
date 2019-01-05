var Game = artifacts.require("Game");
var GameMock = artifacts.require("GameMock");

module.exports = async function(deployer) {
  deployer.deploy(Game, { gas: 6790000 });
  // deployer.deploy(GameMock, {
  //   gas: 6721000,
  //   value: web3.toWei(10)truff
  // });
};
