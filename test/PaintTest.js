const Game = artifacts.require("Game");

let game;
let currentRound;
let color = 1;
let callPriceForColor;

contract("Paint Test", async accounts => {
  beforeEach(async function() {
    game = await Game.new({ gas: 6000000 });
    currentRound = await game.currentRound.call();
  });

  it("Color bank filled for 40% of paint call price", async () => {
    callPriceForColor = await game.callPriceForColor(color);
    await game.paint(1, color, { value: callPriceForColor });
    let colorBankForRound = await game.colorBankForRound(currentRound);
    assert.equal(colorBankForRound.toNumber(), callPriceForColor * 0.4);
  });

  it("Time bank filled for 40% of paint call price", async () => {
    callPriceForColor = await game.callPriceForColor(color);
    await game.paint(1, color, { value: callPriceForColor });
    let timeBankForRound = await game.timeBankForRound(currentRound);
    assert.equal(timeBankForRound.toNumber(), callPriceForColor * 0.4);
  });

  it("Pixel owner's dividends withdrawal balance filled for 5% of paint call price", async () => {
    callPriceForColor = await game.callPriceForColor(color);
    let ownerOfPixel = await game.ownerOfPixel.call();
    let initialBalance = await game.withdrawalBalances(ownerOfPixel);
    await game.paint(1, color, { value: callPriceForColor });
    let newBalance = await game.withdrawalBalances(ownerOfPixel);
    let difference = newBalance - initialBalance;
    assert.equal(difference, callPriceForColor * 0.05);
  });

  it("Color owner's dividends withdrawal balance filled for 5% of paint call price", async () => {
    callPriceForColor = await game.callPriceForColor(color);
    let ownerOfColor = await game.ownerOfColor(color);
    let initialBalance = await game.withdrawalBalances(ownerOfColor);
    await game.paint(1, color, { value: callPriceForColor });
    let newBalance = await game.withdrawalBalances(ownerOfColor);
    let difference = newBalance - initialBalance;
    assert.equal(difference, callPriceForColor * 0.05);
  });

  it("Game founders' dividends withdrawal balance filled for 5% of paint call price", async () => {
    callPriceForColor = await game.callPriceForColor(color);
    let founders = await game.founders.call();
    let initialBalance = await game.withdrawalBalances(founders);
    await game.paint(1, color, { value: callPriceForColor });
    let newBalance = await game.withdrawalBalances(founders);
    let difference = newBalance - initialBalance;
    assert.equal(difference, callPriceForColor * 0.05);
  });
});
