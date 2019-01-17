const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");

let erc1538Delegate;
let router;
let wrapper;

let currentRound;
let color = 1;
let callPrice;

contract("Bank share test", async accounts => {
  beforeEach(async function() {
    erc1538Delegate = await ERC1538Delegate.deployed();
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
    currentRound = await wrapper.currentRound.call();
  });
  it("User should be a team member", async () => {
    let pixels = [];
    let color = 2;
    let user = accounts[1];
    for (i = 1; i < 26; i++) {
      pixels.push(i);
    }
    callPrice = await wrapper.estimateCallPrice(pixels, color);
    await wrapper.paint(pixels, color, "", { value: callPrice, from: user });
    let cbIteration = await wrapper.cbIteration;
    let cbShare = await wrapper.colorBankShare(cbIteration, color, user);
    console.log("Color bank share of user1:", cbShare);
  });
});
