const Game = artifacts.require("Game");

let game;

contract("Paint Discount Test", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    game = await Game.deployed();
  });

  it("currentRound should equal 1", async () => {
    let currentRound = await game.currentRound.call();
    assert.equal(currentRound, 1);
  });

  it("current paint gen should equal 1", async () => {
    let currentPaintGen = await game.currentPaintGenForColor(1);
    assert.equal(currentPaintGen, 1);
  });

  it("User's paint discount for the 1st color should equal to 0 at first", async () => {
    let discount = await game.usersPaintDiscountForColor(1, accounts[1]);
    assert.equal(discount, 0);
  });

  it("User's paint discount for the 1st color should equal 1% after purchasing paints for 1 ETH", async () => {
    let color = 1;
    for (i = 1; i <= 100; ++i) {
      let callPrice = await game.callPriceForColor(color);
      await game.paint(i, color, { value: callPrice });
    }

    let discount = await game.usersPaintDiscountForColor(color, accounts[0]);

    let weiSpent = await game.moneySpentByUserForColor(color, accounts[0]);
    let etherSpent = web3.fromWei(weiSpent);

    assert.equal(discount, 1);
  });

  it("After getting discount, the call price should be with 1 % discount = 0.0099 ETH", async () => {
    let color = 1;

    let callPrice = await game.callPriceForColor(color);

    let discount = await game.usersPaintDiscountForColor(color, accounts[0]);

    let discountCallPrice = (callPrice * (100 - discount)) / 100;
    let expectedCallPrice = web3.toWei(0.0099);
    assert.equal(discountCallPrice, expectedCallPrice);
  });

  it("has discount for color", async () => {
    let color = 1;

    let callPrice = await game.callPriceForColor(color);

    let discount = await game.usersPaintDiscountForColor(color, accounts[0]);
    let hasDiscountForColor = await game.hasPaintDiscountForColor(
      color,
      accounts[0]
    );
    let discountCallPrice = (callPrice * (100 - discount)) / 100;
    let expectedCallPrice = web3.toWei(0.0099);
    assert.equal(hasDiscountForColor, true);
  });
});
