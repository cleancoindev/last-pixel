const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");

let erc1538Delegate;
let router;
let wrapper;

let currentRound;
let color = 1;
let callPrice;

contract("Paint Test", async accounts => {
  beforeEach(async function() {
    erc1538Delegate = await ERC1538Delegate.deployed();
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
    currentRound = await wrapper.currentRound.call();
  });

  it("All tests of painting test are passed", async () => {
    callPrice = await wrapper.estimateCallPrice([1], color);

    let ownerOfPixel = await wrapper.ownerOfPixel.call();
    let initialBalanceOfPixelOwner = await wrapper.withdrawalBalances(
      ownerOfPixel
    );

    let ownerOfColor = await wrapper.ownerOfColor(color);
    let initialBalanceOfColorOwner = await wrapper.withdrawalBalances(
      ownerOfColor
    );

    let founders = await wrapper.founders.call();
    let initialBalanceOfFounders = await wrapper.withdrawalBalances(founders);

    await wrapper.paint([1], color, "", { value: callPrice });

    //Color bank filled for 40% of paint call price
    let colorBankForRound = await wrapper.colorBankForRound(currentRound);
    assert.equal(colorBankForRound.toNumber(), callPrice * 0.4);

    //Time bank filled for 40% of paint call price
    let timeBankForRound = await wrapper.timeBankForRound(currentRound);
    assert.equal(timeBankForRound.toNumber(), callPrice * 0.4);

    //Pixel owner's dividends withdrawal balance filled for 5% of paint call price
    let newBalanceOfPixelOwner = await wrapper.withdrawalBalances(ownerOfPixel);
    let differenceForPixelOwner =
      newBalanceOfPixelOwner - initialBalanceOfPixelOwner;
    assert.equal(differenceForPixelOwner, callPrice * 0.05);

    //Color owner's dividends withdrawal balance filled for 5% of paint call price
    let newBalanceForColorOwner = await wrapper.withdrawalBalances(
      ownerOfColor
    );
    let differenceForColorOwner =
      newBalanceForColorOwner - initialBalanceOfColorOwner;
    assert.equal(differenceForColorOwner, callPrice * 0.05);

    //wrapper founders' dividends withdrawal balance filled for 5% of paint call price
    let newBalanceForFounders = await wrapper.withdrawalBalances(founders);
    let differenceForFounders =
      newBalanceForFounders - initialBalanceOfFounders;
    assert.equal(differenceForFounders, callPrice * 0.05);
  });

  it("Can batch paint 25 pixels at once", async () => {
    let pixels = [];
    for (i = 2; i < 27; i++) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice });
  });
});
