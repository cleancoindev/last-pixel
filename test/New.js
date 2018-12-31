const GameMock = artifacts.require("GameMock");
const helper = require("./helpers/truffleTestHelper");

let gameMock;
let user1;
let user2;
let user3;

contract("NewTests", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    gameMock = await GameMock.deployed();
    user1 = accounts[1];
    user2 = accounts[2];
    user3 = accounts[3];
  });

  it("1 round", async () => {
    currentRound = await gameMock.currentRound.call();
    console.log("\nCurrent round:", currentRound.toNumber());

    //1 пользователь краской 1 (5 раз)
    pixels = [1, 2, 3, 4, 5];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user1, value: callPrice });
    console.log("user1 is painting pixels 1-5 with color", color);

    //2 пользователь краской 2 (3 раза) и краской 3 (3 раза)
    pixels = [6, 7, 8];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user2, value: callPrice });
    console.log("user2 is painting pixels 6-8 with color", color);

    pixels = [9, 10, 11];
    color = 3;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user2, value: callPrice });
    console.log("user2 is painting pixels 9-11 with color", color);

    await gameMock.hardCode2();
    console.log("hardcoding..."); //9998

    //user3 должен стать победителем, раунд должен стать 2-ым
    //user1 и user2 должны иметь на балансе бабки
    pixels = [12, 13];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user3, value: callPrice });
    console.log("user2 is painting pixels 12-13 with color", color);

    currentRound = await gameMock.currentRound.call();
    console.log("\nCurrent round:", currentRound.toNumber());

    let user1Money = await gameMock.colorBankPrizeToBeWithdrawn[user1];
    console.log("User1 money:", user1Money);

    await gameMock.addBankPrizeForLastPlayedRound({ from: user1 });

    user1Money = await gameMock.colorBankPrizeToBeWithdrawn[user1];
    console.log("User1 money:", user1Money);
  });
});
