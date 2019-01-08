var Game = artifacts.require("Game");
var ColorTeam = artifacts.require("ColorTeam");
var TimeTeam = artifacts.require("TimeTeam");
var DividendsDistributor = artifacts.require("DividendsDistributor");
var GameStateController = artifacts.require("GameStateController");
var Referral = artifacts.require("Referral");
var Roles = artifacts.require("Roles");

module.exports = async function(deployer) {
  deployer.deploy(Game, { gas: 5000000 });
  deployer.deploy(ColorTeam);
  deployer.deploy(TimeTeam);
  deployer.deploy(DividendsDistributor);
  deployer.deploy(GameStateController);
  deployer.deploy(Referral);
  deployer.deploy(Roles);
};
