const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");
const helper = require("./helpers/truffleTestHelper");

let erc1538Delegate;
let router;
let wrapper;

let color;
let callPrice;
let timebank1;
let timebank2;

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
    let pixels1 = [];
    for (i = 1; i <= 20; i++) {
      pixels1.push(i);
    }
    color = 1;
    callPrice = await wrapper.estimateCallPrice(pixels1, color);
    await wrapper.paint(pixels1, color, "", {
      value: callPrice,
      from: accounts[1]
    });

    // 2nd user paints next 20 pixels with color 2
    let pixels2 = [];
    for (i = 21; i <= 50; i++) {
      pixels2.push(i);
    }
    color = 2;
    callPrice = await wrapper.estimateCallPrice(pixels2, color);
    await wrapper.paint(pixels2, color, "", {
      value: callPrice,
      from: accounts[2]
    });

    //20 minutes have passed
    const advancement = 20 * 60; //20 minutes
    await helper.advanceTimeAndBlock(advancement);

    // //Time bank
    timebank1 = await wrapper.timeBankForRound(currentRound);
    console.log("Time bank:", timebank1.toNumber());

    //This paint doesn't count and will revert, since 20 minutes have passed by
    callPrice = await wrapper.estimateCallPrice([11], 3);
    await wrapper.paint([11], 3, "", { from: accounts[3], value: callPrice });

    let timebank = await wrapper.timeBankForRound(currentRound);
    console.log("Time bank:", timebank.toNumber()); // 90000000000000000

    await wrapper.distributeTBP();
    console.log("Distributing time bank prize for round 1...");

    let tbIteration = await wrapper.tbIteration.call(); //2
    currentRound = await wrapper.currentRound.call(); //2

    let winner = await wrapper.winnerOfRound(currentRound - 1);
    let share = await wrapper.timeBankShare(tbIteration - 1, winner);

    let paints = 50; //50 paints have been made
    let prize = (timebank * share) / paints;
    let tbp = await wrapper.painterToTBP(tbIteration - 1, winner);
    let amount = timebank.toNumber() + prize;
    assert.equal(+tbp, amount);
  });

  it("The new round has started", async () => {
    let currentRound = await wrapper.currentRound.call();
    console.log("Current round:", currentRound.toNumber());

    assert.equal(currentRound.toNumber(), 2);
  });

  it("New round has 10% of previous round's Time Bank", async () => {
    let currentRound = await wrapper.currentRound.call();
    timebank2 = await wrapper.timeBankForRound(currentRound);

    assert.equal(timebank2.toNumber(), timebank1 * 0.1);
  });

  it("All pixels in new round should be transparent", async () => {
    let currentRound = await wrapper.currentRound.call();
    let transparent = 0;
    for (i = 1; i <= 40; i++) {
      let pixelColor = await wrapper.pixelToColorForRound(currentRound, i);

      //console.log("Color of pixel", i, "is", pixelColor.toNumber());
      assert.equal(pixelColor.toNumber(), transparent);
    }
  });
});
