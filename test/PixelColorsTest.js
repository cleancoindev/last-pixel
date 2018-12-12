const Game = artifacts.require("Game");

let game;

contract("Color Bank Distribution Test", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    game = await Game.deployed();
  });

  it("All pixels should be transparent at the beginning of game", async () => {
    let currentRound = await game.currentRound.call();
    let transparentColor = 0;
    //10000
    for (i = 1; i <= 10; i++) {
      let pixelColor = await game.pixelToColorForRound(currentRound, i);
      assert.equal(pixelColor, transparentColor);
    }
  });
});
