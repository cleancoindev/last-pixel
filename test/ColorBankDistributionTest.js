const Game = artifacts.require("Game");
const GameMock = artifacts.require("GameMock");

let game;
let gameMock;

contract("Color Bank Distribution Test", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    game = await Game.deployed();
    gameMock = await GameMock.deployed();
  });

  it("Last painter of 10000th pixel should get 50% of colorBank", async () => {
    let user = accounts[4];

    let currentRound = await gameMock.currentRound.call();
    console.log("Current round:", currentRound.toNumber());
    let callPrice2 = await gameMock.estimateCallPrice([45], 2);
    let callPrice3 = await gameMock.estimateCallPrice([46], 3);

    //пользователь сделал в этом раунде два закрашивания - оба не цветами победителями
    await gameMock.paint([45], 3, { value: callPrice3, from: accounts[3] });
    await gameMock.paint([46], 1, { value: callPrice3, from: accounts[3] });

    await gameMock.paint9998pixels(2, { from: user });
    await gameMock.paint([1], 2, { value: callPrice2, from: user });

    let initialBalance = await web3.eth.getBalance(user);
    let lastPaint = await gameMock.paint([2], 2, {
      value: callPrice2,
      from: user
    });
    console.log(
      "Color of pixel 1 is:",
      (await gameMock.pixelToColorForRound(currentRound, 1)).toNumber()
    );
    console.log(
      "Color of pixel 2 is:",
      (await gameMock.pixelToColorForRound(currentRound, 2)).toNumber()
    );

    let colorBank = await gameMock.colorBankForRound(currentRound);
    console.log(
      "TimeBank is:",
      (await gameMock.timeBankForRound(currentRound)).toNumber()
    );
    let finalBalance = await web3.eth.getBalance(user);

    let difference = finalBalance - initialBalance;
    let amount = await gameMock.colorBankPrizeOfLastPainter.call();
    //console.log(colorBank.toNumber());
    //assert.equal(difference + gasPrice * gasUsed, web3.toWei(2.008 * 0.5));
    assert.equal(amount.toNumber(), colorBank);
    //assert.equal(pixelsPainted.toNumber(), 10000);
    //assert.equal(colorBank.toNumber() * 2, web3.toWei(2.008));
  });

  it("All pixels should be transparent after the new round has started", async () => {
    let currentRound = await gameMock.currentRound.call();
    let transparentColor = 0;
    console.log("Current round:", currentRound.toNumber());
    console.log(
      "Color of pixel 1 is:",
      (await gameMock.pixelToColorForRound(currentRound, 1)).toNumber()
    );
    console.log(
      "Color of pixel 2 is:",
      (await gameMock.pixelToColorForRound(currentRound, 2)).toNumber()
    );

    console.log(
      "TimeBank is:",
      (await gameMock.timeBankForRound(currentRound)).toNumber()
    );
    //10000
    for (i = 1; i <= 10; i++) {
      let pixelColor = await gameMock.pixelToColorForRound(currentRound, i);
      assert.equal(pixelColor, transparentColor);
    }
  });

  it("Членство в команде цвета должно сохраниться", async () => {
    let user = accounts[4];

    let currentRound = await gameMock.currentRound.call();
    console.log("Current round:", currentRound.toNumber());
    let callPrice = await gameMock.callPriceForColor(2);
  });

  //   it("Color Bank should equal 1.18808 ETH after 300 paints", async () => {
  //     let currentRound = await game.currentRound.call();
  //     let color = 2;
  //     //10000

  //     for (i = 1; i <= 300; i++) {
  //       let hasPaintDiscount = await game.hasPaintDiscountForColor(
  //         color,
  //         accounts[1]
  //       );
  //       let callPrice = await game.callPriceForColor(color);
  //       let discount = await game.usersPaintDiscountForColor(color, accounts[1]);

  //       let discountCallPrice = (callPrice * (100 - discount)) / 100;

  //       if (hasPaintDiscount) {
  //         await game.paint(i, color, {
  //           value: discountCallPrice,
  //           from: accounts[1]
  //         });
  //       } else {
  //         await game.paint(i, color, { value: callPrice, from: accounts[1] });
  //       }
  //     }
  //     let colorBank = await game.colorBankForRound(currentRound);
  //     assert.equal(colorBank.toNumber(), 1188080000000000000);
  //   });
});
