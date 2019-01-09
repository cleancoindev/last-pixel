const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");

let wrapper;
let router;

contract("Paint Discount Test", async accounts => {
  beforeEach(async function() {
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
  });

  it("currentRound should equal 1", async () => {
    let currentRound = await wrapper.currentRound.call();
    assert.equal(currentRound, 1);
  });

  it("current paint gen should equal 1", async () => {
    let currentPaintGen = await wrapper.currentPaintGenForColor(1);
    assert.equal(currentPaintGen, 1);
  });

  it("User's paint discount for the 1st color should equal to 0 at first", async () => {
    let discount = await wrapper.usersPaintDiscountForColor(1, accounts[1]);
    assert.equal(discount, 0);
  });

  it("User's paint discount for the 1st color should equal 1% after purchasing paints for 1 ETH", async () => {
    let color = 1;
    //first 30 pixels
    let pixels = [];
    for (i = 1; i <= 30; ++i) {
      pixels.push(i);
    }
    let callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });

    //second 30 pixels
    pixels = [];
    for (i = 31; i <= 60; ++i) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });

    //pixels 60 - 90
    pixels = [];
    for (i = 61; i <= 90; ++i) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });

    //pixels 90 - 100
    pixels = [];
    for (i = 91; i <= 100; ++i) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });
    let discount = await wrapper.usersPaintDiscountForColor(color, accounts[0]);
    let weiSpent = await wrapper.moneySpentByUserForColor(color, accounts[0]);
    let etherSpent = web3.fromWei(weiSpent);

    assert.equal(discount, 1);
  });

  it("After getting discount, the call price should be with 1 % discount = 0.0099 ETH", async () => {
    let color = 1;
    let callPrice = await wrapper.callPriceForColor(color);
    let discount = await wrapper.usersPaintDiscountForColor(color, accounts[0]);
    let discountCallPrice = (callPrice * (100 - discount)) / 100;
    let expectedCallPrice = web3.toWei(0.0099);
    assert.equal(discountCallPrice, expectedCallPrice);
  });

  it("has discount for color", async () => {
    let color = 1;
    let callPrice = await wrapper.callPriceForColor(color);
    let discount = await wrapper.usersPaintDiscountForColor(color, accounts[0]);
    let hasDiscountForColor = await wrapper.hasPaintDiscountForColor(
      color,
      accounts[0]
    );
    let discountCallPrice = (callPrice * (100 - discount)) / 100;
    let expectedCallPrice = web3.toWei(0.0099);
    assert.equal(hasDiscountForColor, true);
  });
});
