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
const GameMock = artifacts.require("GameMock");
const Helpers = artifacts.require("helpers");

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
let gameMock;
let helpers;

module.exports = async function(deployer) {
  deployer
    .then(function() {
      console.log("\n");
      return ERC1538Delegate.deployed();
    })
    .then(function(instance) {
      erc1538Delegate = instance;
      console.log("ERC1538 Delegate:", erc1538Delegate.address);
      return Router.deployed();
    })
    .then(function(instance) {
      router = instance;
      console.log("Router:", router.address);
      return Wrapper.at(router.address);
    })
    .then(function(instance) {
      wrapper = instance;
      console.log("Wrapper:", wrapper.address);
      return Game.deployed();
    })
    .then(function(instance) {
      game = instance;
      console.log("Game:", game.address);
      return ColorTeam.deployed();
    })
    .then(function(instance) {
      colorTeam = instance;
      console.log("Color Team:", colorTeam.address);
      return TimeTeam.deployed();
    })
    .then(function(instance) {
      timeTeam = instance;
      console.log("Time Team:", timeTeam.address);
      return DividendsDistributor.deployed();
    })
    .then(function(instance) {
      dividendsDistributor = instance;
      console.log("Dividends Distributor:", dividendsDistributor.address);
      return GameStateController.deployed();
    })
    .then(function(instance) {
      gameStateController = instance;
      console.log("Game State Controller:", gameStateController.address);
      return Referral.deployed();
    })
    .then(function(instance) {
      referral = instance;
      console.log("Referral:", referral.address);
      return Roles.deployed();
    })
    .then(function(instance) {
      roles = instance;
      console.log("Roles:", roles.address);
      return GameMock.deployed();
    })
    .then(function(instance) {
      gameMock = instance;
      console.log("Game Mock:", gameMock.address);
      return Helpers.deployed();
    })
    .then(function(instance) {
      helpers = instance;
      console.log("Helpers:", helpers.address);
      console.log("\n");
      console.log("Adding functions from ERC1538QueryDelegates.sol");
      return wrapper.updateContract(
        erc1538Delegate.address,
        "functionByIndex(uint256)functionExists(string)delegateAddress(string)delegateAddresses()delegateFunctionSignatures(address)functionById(bytes4)functionBySignature(string)functionSignatures()totalFunctions()",
        "Added functions from ERC1538QueryDelegates.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from Game.sol");
      return wrapper.updateContract(
        game.address,
        "estimateCallPrice(uint256[],uint256)paint(uint256[],uint256,string)drawTimeBank()",
        "Added functions from Game.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from ColorTeam.sol");
      return wrapper.updateContract(
        colorTeam.address,
        "distributeCBP()",
        "Added functions from ColorTeam.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from TimeTeam.sol");
      return wrapper.updateContract(
        timeTeam.address,
        "distributeTBP()",
        "Added functions from TimeTeam.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from DividendsDistributor.sol");
      return wrapper.updateContract(
        dividendsDistributor.address,
        "claimDividends()approveClaim(uint256)",
        "Added functions from DividendsDistributor.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from GameStateController.sol");
      return wrapper.updateContract(
        gameStateController.address,
        "pauseGame()resumeGame()withdrawEther()",
        "Added functions from GameStateController.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from Referral.sol");
      return wrapper.updateContract(
        referral.address,
        "buyRefLink(string)getReferralsForUser(address)getReferralData(address)",
        "Added functions from Referral.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from Roles.sol");
      return wrapper.updateContract(
        roles.address,
        "addAdmin(address)removeAdmin(address)renounceAdmin()",
        "Added functions from Roles.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from GameMock.sol");
      return wrapper.updateContract(
        gameMock.address,
        "mock()mock2()mock3(uint256)mockMaxPaintsInPool()",
        "Added functions from GameMock.sol"
      );
    })
    .then(function() {
      console.log("Adding functions from Helpers.sol");
      return wrapper.updateContract(
        helpers.address,
        "getPixelColor(uint256)addNewColor()",
        "Added functions from Helpers.sol"
      );
    });
};
