const GameMock = artifacts.require("GameMock");

const helper = require("./helpers/truffleTestHelper");
let gameMock;
let timeBankForRoundOne;
let timeBankForRoundTwo;

contract("Time Bank Tests", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    gameMock = await GameMock.deployed();
  });

  it("Winner should receive 45% of Time Bank", async () => {
    let currentRound = await gameMock.currentRound.call();
    console.log("Current round:", currentRound.toNumber());

    // 1st user paints 20 pixels with color 1
    for (i = 1; i <= 20; i++) {
      let user = accounts[1];
      let color = 1;
      let callPrice = await gameMock.nextCallPriceForColor(color);
      await gameMock.paint(i, color, { value: callPrice, from: user });
      let pixelColor = await gameMock.pixelToColorForRound(currentRound, i);
      //console.log("User 1 is painting pixel", i, "with color 1");
      console.log("Color of pixel", i, "is", pixelColor.toNumber());
    }

    // 2nd user paints next 20 pixels with color 2
    for (i = 21; i <= 40; i++) {
      let user = accounts[2];
      let color = 2;
      let callPrice = await gameMock.nextCallPriceForColor(color);
      await gameMock.paint(i, color, { value: callPrice, from: user });

      //console.log("User 2 is painting pixel", i, "with color 2");
      let pixelColor = await gameMock.pixelToColorForRound(currentRound, i);
      console.log("Color of pixel", i, "is", pixelColor.toNumber());
    }

    //20 minutes have passed
    const advancement = 20 * 60; //20 minutes
    await helper.advanceTimeAndBlock(advancement);

    //Time bank
    timeBankForRoundOne = await gameMock.timeBankForRound(currentRound);
    console.log("Time Bank: ", timeBankForRoundOne.toNumber());

    //This paint doesn't count and will revert, since 20 minutes have passed by
    let callPrice = await gameMock.nextCallPriceForColor(3);
    await gameMock.paint(11, 3, { from: accounts[3], value: callPrice });

    //Time bank prize that the last painter will get
    let amount = await gameMock.timeBankPrizeOfLastPainter.call();
    console.log("Winner should get:", web3.fromWei(amount).toNumber());

    assert.equal(amount.toNumber(), timeBankForRoundOne * 0.45);
  });

  it("The new round has started", async () => {
    let currentRound = await gameMock.currentRound.call();
    console.log("Current round:", currentRound.toNumber());

    assert.equal(currentRound.toNumber(), 2);
  });

  it("New round has 10% of previous round's Time Bank", async () => {
    let currentRound = await gameMock.currentRound.call();
    timeBankForRoundTwo = await gameMock.timeBankForRound(currentRound);

    assert.equal(timeBankForRoundTwo.toNumber(), timeBankForRoundOne * 0.1);
  });

  it("All pixels in new round should be transparent", async () => {
    let currentRound = await gameMock.currentRound.call();
    let transparent = 0;
    for (i = 1; i <= 40; i++) {
      let pixelColor = await gameMock.pixelToColorForRound(currentRound, i);

      console.log("Color of pixel", i, "is", pixelColor.toNumber());
      assert.equal(pixelColor.toNumber(), transparent);
    }
  });
});
