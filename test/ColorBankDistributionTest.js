const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");

let erc1538Delegate;
let router;
let wrapper;

contract("Color Bank Distribution Test", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    erc1538Delegate = await ERC1538Delegate.deployed();
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
    currentRound = await wrapper.currentRound.call();
  });

  it("Last painter of 10000th pixel should get 50% of colorBank", async () => {
    let user = accounts[4];

    let currentRound = await wrapper.currentRound.call();
    console.log("Current round:", currentRound.toNumber());
    let callPrice2 = await wrapper.estimateCallPrice([45], 2);
    let callPrice3 = await wrapper.estimateCallPrice([46], 3);

    //пользователь сделал в этом раунде два закрашивания - оба не цветами победителями
    await wrapper.paint([45], 3, "", { value: callPrice3, from: accounts[3] });
    await wrapper.paint([46], 1, "", { value: callPrice3, from: accounts[3] });

    await wrapper.mock2();

    await wrapper.paint([1], 2, "", { value: callPrice2, from: user });

    let initialBalance = await web3.eth.getBalance(user);
    let lastPaint = await wrapper.paint([2], 2, "", {
      value: callPrice2,
      from: user
    });
    console.log(
      "Color of pixel 1 is:",
      (await wrapper.pixelToColorForRound(currentRound, 1)).toNumber()
    );
    console.log(
      "Color of pixel 2 is:",
      (await wrapper.pixelToColorForRound(currentRound, 2)).toNumber()
    );

    let colorBank = await wrapper.colorBankForRound(currentRound);
    console.log(
      "ColorBank is:",
      (await wrapper.colorBankForRound(currentRound)).toNumber()
    );
    let finalBalance = await web3.eth.getBalance(user);

    let difference = finalBalance - initialBalance;
    let cbIteration = await wrapper.cbIteration.call();
    currentRound = await wrapper.currentRound.call();
    let winner = await wrapper.winnerOfRound(currentRound);
    let amount = await wrapper.painterToCBP(cbIteration, winner);

    assert.equal(+amount, +colorBank);
  });

  // it("All pixels should be transparent after the new round has started", async () => {
  //   let currentRound = await wrapper.currentRound.call();
  //   let transparentColor = 0;
  //   console.log("Current round:", currentRound.toNumber());
  //   console.log(
  //     "Color of pixel 1 is:",
  //     (await wrapper.pixelToColorForRound(currentRound, 1)).toNumber()
  //   );
  //   console.log(
  //     "Color of pixel 2 is:",
  //     (await wrapper.pixelToColorForRound(currentRound, 2)).toNumber()
  //   );

  //   console.log(
  //     "TimeBank is:",
  //     (await wrapper.timeBankForRound(currentRound)).toNumber()
  //   );
  //   //10000
  //   for (i = 1; i <= 10; i++) {
  //     let pixelColor = await wrapper.pixelToColorForRound(currentRound, i);
  //     assert.equal(pixelColor, transparentColor);
  //   }
  // });

  // it("Членство в команде цвета должно сохраниться", async () => {
  //   let user = accounts[4];

  //   let currentRound = await wrapper.currentRound.call();
  //   console.log("Current round:", currentRound.toNumber());
  //   let callPrice = await wrapper.callPriceForColor(2);
  // });
});
