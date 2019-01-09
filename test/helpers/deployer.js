const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Game = artifacts.require("Game");
const ColorTeam = artifacts.require("ColorTeam");
const TimeTeam = artifacts.require("TimeTeam");
const DividendsDistributor = artifacts.require("DividendsDistributor");
const GameStateController = artifacts.require("GameStateController");
const Referral = artifacts.require("Referral");
const Roles = artifacts.require("Roles");
const Wrapper = artifacts.require("Wrapper");

// Contract instances
let erc1538Delegate;
let router;
let game;
let colorTeam;
let timeTeam;
let dividendsDistributor;
let gameStateController;
let referral;
let roles;
let wrapper;

deploy = () => {
  return new Promise((resolve, reject) => {
    console.log("\n");
    return ERC1538Delegate.new();
  })
    .then(function(instance) {
      erc1538Delegate = instance;
      console.log("ERC1538 Delegate:", erc1538Delegate.address);
      return Router.new(erc1538Delegate.address, { gas: 5000000 });
    })
    .then(function(instance) {
      router = instance;
      console.log("Router:", router.address);
      return Wrapper.at(router.address);
    })
    .then(function(instance) {
      wrapper = instance;
      console.log("Wrapper:", wrapper.address);
      return Game.new();
    })
    .then(function(instance) {
      game = instance;
      console.log("Game:", game.address);
      return ColorTeam.new();
    })
    .then(function(instance) {
      colorTeam = instance;
      console.log("Color Team:", colorTeam.address);
      return TimeTeam.new();
    })
    .then(function(instance) {
      timeTeam = instance;
      console.log("Time Team:", timeTeam.address);
      return DividendsDistributor.new();
    })
    .then(function(instance) {
      dividendsDistributor = instance;
      console.log("Dividends Distributor:", dividendsDistributor.address);
      return GameStateController.new();
    })
    .then(function(instance) {
      gameStateController = instance;
      console.log("Game State Controller:", gameStateController.address);
      return Referral.new();
    })
    .then(function(instance) {
      referral = instance;
      console.log("Referral:", referral.address);
      return Roles.new();
    })
    .then(function(instance) {
      roles = instance;
      console.log("Roles:", roles.address);
      console.log("\n");
      return wrapper.updateContract(
        erc1538Delegate.address,
        "functionByIndex(uint256)functionExists(string)delegateAddress(string)delegateAddresses()delegateFunctionSignatures(address)functionById(bytes4)functionBySignature(string)functionSignatures()totalFunctions()",
        "Added functions from ERC1538QueryDelegates.sol"
      );
    })
    .then(function() {
      return wrapper.updateContract(
        game.address,
        "getPixelColor(uint256)estimateCallPrice(uint256[],uint256)paint(uint256[],uint256,string)",
        "Added functions from Game.sol"
      );
    })
    .then(function() {
      return wrapper.updateContract(
        colorTeam.address,
        "distributeCBP()",
        "Added function from ColorTeam.sol"
      );
    })
    .then(function() {
      return wrapper.updateContract(
        timeTeam.address,
        "distributeTBP()",
        "Added function from TimeTeam.sol"
      );
    })
    .then(function() {
      return wrapper.updateContract(
        dividendsDistributor.address,
        "claimDividends()approveClaim(uint256)",
        "Added function from DividendsDistributor.sol"
      );
    })
    .then(function() {
      return wrapper.updateContract(
        gameStateController.address,
        "pauseGame()resumeGame()",
        "Added function from GameStateController.sol"
      );
    })
    .then(function() {
      return wrapper.updateContract(
        referral.address,
        "buyRefLink(string)",
        "Added function from Referral.sol"
      );
    })
    .then(function() {
      return wrapper.updateContract(
        roles.address,
        "addAdmin(address)removeAdmin(address)renounceAdmin()",
        "Added functions from Roles.sol"
      );
    });
};

module.exports = {
  deploy
};
