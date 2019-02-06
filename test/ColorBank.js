const ERC1538Delegate = artifacts.require("ERC1538Delegate");
const Router = artifacts.require("Router");
const Wrapper = artifacts.require("Wrapper");

let erc1538Delegate;
let router;
let wrapper;

contract("Color Bank Distribution Test", async accounts => {
  beforeEach(async function() {
    erc1538Delegate = await ERC1538Delegate.deployed();
    router = await Router.deployed();
    wrapper = await Wrapper.at(router.address);
    currentRound = await wrapper.currentRound.call();
  });

  it("Last painter (user 3) should get 50% of colorBank", async () => {
    let currentRound = await wrapper.currentRound.call();
    console.log("Current round:", currentRound.toNumber());

    let callPrice = await wrapper.estimateCallPrice([45, 46, 47, 48], 2);
    //пользователь сделал в этом раунде два закрашивания - оба не цветами победителями
    await wrapper.paint([45, 46, 47, 48], 2, "", {
      value: callPrice,
      from: accounts[1]
    });

    callPrice = await wrapper.estimateCallPrice([49, 50, 51, 52], 3);

    await wrapper.paint([49, 50, 51, 52], 2, "", {
      value: callPrice,
      from: accounts[1]
    });

    await wrapper.mock3(2);

    callPrice = await wrapper.estimateCallPrice([1], 2);
    await wrapper.paint([1], 2, "", { value: callPrice, from: accounts[2] });

    let colorBank = await wrapper.colorBankForRound(currentRound); //0.036
    console.log("ColorBank before last paint is:", +colorBank);

    let lastPaint = await wrapper.paint([2], 2, "", {
      value: callPrice,
      from: accounts[3]
    });

    let colorBankAfterLastPaint = await wrapper.colorBankForRound(currentRound); //0.04/2 = 0.02
    console.log(
      "ColorBank after last paint is:",
      colorBankAfterLastPaint.toNumber()
    );

    await wrapper.distributeCBP();

    let cbIteration = await wrapper.cbIteration.call();
    currentRound = await wrapper.currentRound.call();

    let winner = await wrapper.winnerOfRound(currentRound - 1);

    let winnerColor = await wrapper.winnerColorForRound(currentRound - 1);
    console.log("Winner Color:", +winnerColor);

    let share = await wrapper.colorBankShare(
      cbIteration - 1,
      winnerColor,
      winner
    );
    console.log("Share:", +share);

    let paints = 10; //10 paints have been made
    let prize = (colorBankAfterLastPaint * share) / paints;
    console.log("Prize", +prize);
    let cbp = await wrapper.painterToCBP(cbIteration - 1, winner);
    let amount = colorBankAfterLastPaint.toNumber() + prize;

    let painterInFirstRound = await wrapper.usersCounterForRound(
      currentRound - 1
    );
    console.log("Users count in 1 round:", +painterInFirstRound);
    assert.equal(+cbp, amount);
  });

  it("The new round should start and all pixels should be transparent in it", async () => {
    let currentRound = await wrapper.currentRound.call();
    let painterInSecondRound = await wrapper.usersCounterForRound(currentRound);
    console.log("Users count in 2 round:", +painterInSecondRound);
    let transparentColor = 0;
    console.log("Current round:", currentRound.toNumber());
    console.log(
      "Color of pixel 1 is:",
      (await wrapper.pixelToColorForRound(currentRound, 1)).toNumber()
    );
    console.log(
      "Color of pixel 2 is:",
      (await wrapper.pixelToColorForRound(currentRound, 2)).toNumber()
    );

    console.log(
      "TimeBank is:",
      (await wrapper.timeBankForRound(currentRound)).toNumber()
    );
    //10000
    for (i = 1; i <= 10; i++) {
      let pixelColor = await wrapper.pixelToColorForRound(currentRound, i);
      assert.equal(pixelColor, transparentColor);
    }
  });

  it("User1 should receive his CBP for round 1", async () => {
    let currentRound = await wrapper.currentRound.call();
    let cbIteration = await wrapper.cbIteration.call();
    //accounts[1] has painted 6 times:
    let cbp1 = await wrapper.painterToCBP(cbIteration - 1, accounts[1]);
    let winnerColor = await wrapper.winnerColorForRound(currentRound - 1);
    let shareOfUser1 = await wrapper.colorBankShare(
      cbIteration - 1,
      winnerColor,
      accounts[1]
    );
    let paints = 10; //10 paints have been made in round 1
    let colorBank = await wrapper.colorBankForRound(currentRound - 1); //for round 1
    let prize1 = (colorBank * shareOfUser1) / paints;
    assert.equal(+cbp1, prize1);
  });

  it("User2 should receive his CBP for round 1", async () => {
    let currentRound = await wrapper.currentRound.call();
    let cbIteration = await wrapper.cbIteration.call();
    //accounts[2] has painted once:
    let cbp2 = await wrapper.painterToCBP(cbIteration - 1, accounts[2]);
    let winnerColor = await wrapper.winnerColorForRound(currentRound - 1);
    let shareOfUser2 = await wrapper.colorBankShare(
      cbIteration - 1,
      winnerColor,
      accounts[2]
    );
    let paints = 10; //10 paints have been made in round 1
    let colorBank = await wrapper.colorBankForRound(currentRound - 1); //for round 1
    let prize2 = (colorBank * shareOfUser2) / paints;
    assert.equal(+cbp2, prize2);
  });
});
