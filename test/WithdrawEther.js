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

  it("Should withdraw ether to owner", async () => {
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

    let balanceBefore = web3.eth.getBalance(accounts[0]);
    console.log("balance before: ", +balanceBefore);

    await wrapper.pauseGame();
    let paused = await wrapper.isGamePaused();
    assert.equal(paused, true);

    currentRound = await wrapper.currentRound.call();
    console.log("currentRound: ", +currentRound);

    let timeBank = await wrapper.timeBankForRound(currentRound);
    console.log("timeBank: ", +timeBank);

    let colorBank = await wrapper.colorBankForRound(currentRound);
    console.log("colorBank: ", +colorBank);

    await wrapper.withdrawEther();
    let balanceAfter = web3.eth.getBalance(accounts[0]);
    console.log("balance after: ", +balanceAfter);
  });
});
