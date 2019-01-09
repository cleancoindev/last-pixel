const helper = require("./helpers/deployer");

let currentRound;
let color = 1;
let callPrice;

contract("Paint Test", async accounts => {
  beforeEach(async function() {
    await helper.deploy();
    currentRound = await game.currentRound.call();
  });

  it("Color bank filled for 40% of paint call price", async () => {
    callPrice = await game.estimateCallPrice([1], color);
    await game.paint([1], color, { value: callPrice });
    let colorBankForRound = await game.colorBankForRound(currentRound);
    assert.equal(colorBankForRound.toNumber(), callPrice * 0.4);
  });

  it("Time bank filled for 40% of paint call price", async () => {
    callPrice = await game.estimateCallPrice([1], color);
    await game.paint([1], color, { value: callPrice });
    let timeBankForRound = await game.timeBankForRound(currentRound);
    assert.equal(timeBankForRound.toNumber(), callPrice * 0.4);
  });

  it("Pixel owner's dividends withdrawal balance filled for 5% of paint call price", async () => {
    callPrice = await game.estimateCallPrice([1], color);
    let ownerOfPixel = await game.ownerOfPixel.call();
    let initialBalance = await game.withdrawalBalances(ownerOfPixel);
    await game.paint([1], color, { value: callPrice });
    let newBalance = await game.withdrawalBalances(ownerOfPixel);
    let difference = newBalance - initialBalance;
    assert.equal(difference, callPrice * 0.05);
  });

  it("Color owner's dividends withdrawal balance filled for 5% of paint call price", async () => {
    callPrice = await game.estimateCallPrice([1], color);
    let ownerOfColor = await game.ownerOfColor(color);
    let initialBalance = await game.withdrawalBalances(ownerOfColor);
    await game.paint([1], color, { value: callPrice });
    let newBalance = await game.withdrawalBalances(ownerOfColor);
    let difference = newBalance - initialBalance;
    assert.equal(difference, callPrice * 0.05);
  });

  it("Game founders' dividends withdrawal balance filled for 5% of paint call price", async () => {
    callPrice = await game.estimateCallPrice([1], color);
    let founders = await game.founders.call();
    let initialBalance = await game.withdrawalBalances(founders);
    await game.paint([1], color, { value: callPrice });
    let newBalance = await game.withdrawalBalances(founders);
    let difference = newBalance - initialBalance;
    assert.equal(difference, callPrice * 0.05);
  });
});
