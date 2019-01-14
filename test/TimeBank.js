const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");
const helper = require("./helpers/truffleTestHelper");

let erc1538Delegate;
let router;
let wrapper;

let user;
let color;
let callPrice;

contract("Time Bank Distribution Test", async accounts => {
  beforeEach(async function() {
    erc1538Delegate = await ERC1538Delegate.deployed();
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
    currentRound = await wrapper.currentRound.call();
  });

  it("Winner of round 1 should receive 45% of Time Bank", async () => {
    currentRound = await wrapper.currentRound.call(); //round1
    console.log("Current round:", currentRound.toNumber());

    // 1st user paints 20 pixels with color 1
    for (i = 1; i <= 20; i++) {
      user = accounts[1];
      color = 1;
      callPrice = await wrapper.estimateCallPrice(color);
      await wrapper.paint(i, color, { value: callPrice, from: user });
      let pixelColor = await wrapper.pixelToColorForRound(currentRound, i);
      //console.log("User 1 is painting pixel", i, "with color 1");
      console.log("Color of pixel", i, "is", pixelColor.toNumber());
    }

    // 2nd user paints next 20 pixels with color 2
    for (i = 21; i <= 40; i++) {
      user = accounts[2];
      color = 2;
      callPrice = await wrapper.nextCallPriceForColor(color);
      await wrapper.paint(i, color, { value: callPrice, from: user });

      //console.log("User 2 is painting pixel", i, "with color 2");
      let pixelColor = await wrapper.pixelToColorForRound(currentRound, i);
      console.log("Color of pixel", i, "is", pixelColor.toNumber());
    }

    //20 minutes have passed
    const advancement = 20 * 60; //20 minutes
    await helper.advanceTimeAndBlock(advancement);

    //Time bank
    timeBankForRoundOne = await wrapper.timeBankForRound(currentRound);
    console.log("Time Bank: ", timeBankForRoundOne.toNumber());

    //This paint doesn't count and will revert, since 20 minutes have passed by
    let callPrice = await wrapper.nextCallPriceForColor(3);
    await wrapper.paint(11, 3, { from: accounts[3], value: callPrice });

    //Time bank prize that the last painter will get
    let amount = await wrapper.timeBankPrizeOfLastPainter.call();
    console.log("Winner should get:", web3.fromWei(amount).toNumber());

    assert.equal(amount.toNumber(), timeBankForRoundOne * 0.45);
  });

  it("The new round has started", async () => {
    let currentRound = await wrapper.currentRound.call();
    console.log("Current round:", currentRound.toNumber());

    assert.equal(currentRound.toNumber(), 2);
  });

  it("New round has 10% of previous round's Time Bank", async () => {
    let currentRound = await wrapper.currentRound.call();
    timeBankForRoundTwo = await wrapper.timeBankForRound(currentRound);

    assert.equal(timeBankForRoundTwo.toNumber(), timeBankForRoundOne * 0.1);
  });

  it("All pixels in new round should be transparent", async () => {
    let currentRound = await wrapper.currentRound.call();
    let transparent = 0;
    for (i = 1; i <= 40; i++) {
      let pixelColor = await wrapper.pixelToColorForRound(currentRound, i);

      console.log("Color of pixel", i, "is", pixelColor.toNumber());
      assert.equal(pixelColor.toNumber(), transparent);
    }
  });
});
