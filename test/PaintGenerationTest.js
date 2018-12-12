const GameMock = artifacts.require("GameMock");

const helper = require("./helpers/truffleTestHelper");

let gameMock;

contract("Paint Generation", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    gameMock = await GameMock.deployed();
  });

  it("After 1.5 minutes have passed, the amount of second gen paints should equal to what is used of first", async () => {
    let color = 2;

    for (i = 1; i <= 50; i++) {
      let nextCallPrice = await gameMock.nextCallPriceForColor(color);
      await gameMock.paint(i, color, { value: nextCallPrice });

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
    }

    const advancement = 90; //1.5 minutes
    await helper.advanceTimeAndBlock(advancement);

    let nextCallPrice = await gameMock.nextCallPriceForColor(color);
    await gameMock.paint(51, color, {
      value: nextCallPrice
    });

    let secondGenAmount = await gameMock.paintGenToAmountForColor(color, 2);
    assert.equal(secondGenAmount.toNumber(), 50);
  });

  //
  //
  //
  //
  //
  //

  it("Paint price of current collor has increased by 5%", async () => {
    let color = 2;

    let callprice = await gameMock.nextCallPriceForColor(color);
    for (i = 100; i <= 150; i++) {
      let nextCallPrice = await gameMock.nextCallPriceForColor(color);

      let hasDiscountForColor = await gameMock.hasPaintDiscountForColor(
        color,
        accounts[0]
      );
      let discount = await gameMock.usersPaintDiscountForColor(
        color,
        accounts[0]
      );

      if (hasDiscountForColor) {
        let discountCallPrice = (nextCallPrice * (100 - discount)) / 100;
        //console.log("Discount callprice:", web3.fromWei(discountCallPrice));
        await gameMock.paint(i, color, { value: discountCallPrice });
      } else {
        await gameMock.paint(i, color, { value: nextCallPrice });
      }

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

      console.log("Call Price:", web3.fromWei(nextCallPrice.toNumber()));
      console.log("------------------------------------------------");
    }

    let nextCallPrice = await gameMock.nextCallPriceForColor(color);
    assert.equal(nextCallPrice.toNumber(), callprice * 1.05);
  });
});
