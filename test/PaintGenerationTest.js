const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");
const GameMock = artifacts.require("GameMock");

const helper = require("./helpers/truffleTestHelper");

let gameMock;
let color;
let callPrice;
let pixels;
let wrapper;
let router;

contract("Paint Generation", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    //gameMock = await GameMock.deployed();
    router = await Router.deployed();
    gameMock = await Wrapper.at(router.address);
  });

  it("After 1.5 minutes have passed, the amount of second gen paints should equal to what is used of first", async () => {
    color = 2;
    pixels = [];

    //paint pixels 1-30
    for (i = 1; i <= 30; i++) {
      pixels.push(i);
    }
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, "", { value: callPrice });

    //paint pixels 31-50
    pixels = [];
    for (i = 31; i <= 50; i++) {
      pixels.push(i);
    }
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, "", { value: callPrice });

    let firstGenAmount = await gameMock.paintGenToAmountForColor(color, 1);
    console.log(
      "Paints remaining in first generation: ",
      firstGenAmount.toNumber()
    );

    let secondGenAmount = await gameMock.paintGenToAmountForColor(color, 2);
    console.log(
      "Paints remaining in second generation: ",
      secondGenAmount.toNumber()
    );

    console.log("------------------------------------------------");

    const advancement = 90; //1.5 minutes
    await helper.advanceTimeAndBlock(advancement);

    let nextCallPrice = await gameMock.estimateCallPrice([51], color);
    await gameMock.paint([51], color, "", {
      value: nextCallPrice
    });

    secondGenAmount = await gameMock.paintGenToAmountForColor(color, 2);
    assert.equal(secondGenAmount.toNumber(), 50);
  });

  //
  //
  //
  //
  //
  //

  it("Paint price of current collor has increased by 5%", async () => {
    color = 2;

    //paint pixels 101-150
    pixels = [];
    for (i = 101; i <= 130; i++) {
      pixels.push(i);
    }
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, "", { value: callPrice });

    //paint pixels 131-150
    pixels = [];
    for (i = 131; i <= 150; i++) {
      pixels.push(i);
    }

    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, "", { value: callPrice });

    let firstGenAmount = await gameMock.paintGenToAmountForColor(color, 1);
    console.log(
      "Paints remaining in first generation: ",
      firstGenAmount.toNumber()
    );

    let secondGenAmount = await gameMock.paintGenToAmountForColor(color, 2);
    console.log(
      "Paints remaining in second generation: ",
      secondGenAmount.toNumber()
    );

    nextCallPrice = await gameMock.nextCallPriceForColor(color);
    assert.equal(nextCallPrice.toNumber(), callprice * 1.05);
  });
});
