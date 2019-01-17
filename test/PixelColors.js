const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");

let erc1538Delegate;
let router;
let wrapper;

contract("Pixel Colors Test", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    erc1538Delegate = await ERC1538Delegate.deployed();
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
    currentRound = await wrapper.currentRound.call();
  });

  it("All pixels should be transparent at the beginning of game", async () => {
    let currentRound = await wrapper.currentRound.call();
    let transparentColor = 0;
    //10000
    for (i = 1; i <= 100; i++) {
      let pixelColor = await wrapper.pixelToColorForRound(currentRound, i);
      assert.equal(pixelColor, transparentColor);
    }
  });
});
