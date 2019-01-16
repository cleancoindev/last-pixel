const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");
const helper = require("./helpers/truffleTestHelper");

let color;
let callPrice;
let pixels;

let erc1538Delegate;
let router;
let wrapper;

contract("Paint Generation", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    erc1538Delegate = await ERC1538Delegate.deployed();
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
  });

  it("After 1.5 minutes have passed, the amount of second gen paints should equal to what is used of first", async () => {
    //setting maxPaintInPool = 100 for testing purposes
    await wrapper.mockMaxPaintsInPool();
    let maxPaints = await wrapper.maxPaintsInPool.call();
    console.log("Max paints in pool:", +maxPaints);

    color = 2;
    pixels = [];

    //paint pixels 1-30
    for (i = 1; i <= 30; i++) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });

    //paint pixels 31-50
    pixels = [];
    for (i = 31; i <= 50; i++) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });

    let firstGenAmount = await wrapper.paintGenToAmountForColor(color, 1);
    console.log(
      "Paints remaining in first generation: ",
      firstGenAmount.toNumber()
    );

    let secondGenAmount = await wrapper.paintGenToAmountForColor(color, 2);
    console.log(
      "Paints remaining in second generation: ",
      secondGenAmount.toNumber()
    );

    console.log("------------------------------------------------");

    const advancement = 90; //1.5 minutes
    await helper.advanceTimeAndBlock(advancement);

    let nextCallPrice = await wrapper.estimateCallPrice([51], color);
    await wrapper.paint([51], color, "", {
      value: nextCallPrice
    });

    secondGenAmount = await wrapper.paintGenToAmountForColor(color, 2);
    assert.equal(secondGenAmount.toNumber(), 50);
  });

  it("Paint price of current color has increased by 5%", async () => {
    color = 2;

    //paint pixels 101-150
    pixels = [];
    for (i = 101; i <= 130; i++) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });

    //paint pixels [131-148]
    pixels = [];
    for (i = 131; i < 149; i++) {
      pixels.push(i);
    }

    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });

    let firstGenAmount = await wrapper.paintGenToAmountForColor(color, 1);
    console.log(
      "Paints remaining in first generation: ",
      firstGenAmount.toNumber()
    );

    let secondGenAmount = await wrapper.paintGenToAmountForColor(color, 2);
    console.log(
      "Paints remaining in second generation: ",
      secondGenAmount.toNumber()
    );

    let callprice = await wrapper.callPriceForColor(color);

    nextCallPrice = await wrapper.nextCallPriceForColor(color);
    assert.equal(nextCallPrice.toNumber(), +callprice);
  });
});
