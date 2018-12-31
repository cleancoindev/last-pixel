const GameMock = artifacts.require("GameMock");
const helper = require("./helpers/truffleTestHelper");

let gameMock;
let timeBankForRoundOne;
let timeBankForRoundTwo;
let user1;
let user2;
let user3;
let user4;
let user5;
let callPrice;
let color;
let timeBank;
let colorBank;
let currentRound;
let pixels;

/*
    
    в 1 раунде 5 пользователей делают пэинт - выигрывает банк времени (1 color)
    
        1 пользователь краской 1 (5 раз)
        2 пользователь краской 2 (3 раза) и краской 3 (3 раза)
        3 пользователь краской 1 (3 раза)
        4 пользователь краской 2 (2 раза)
        хардкод (9998) - проходит время и банк цвета не должен разыграться
        5 пользователь краской 1 (1 раз) - последним (выигрывает банк времени)
        
    во 2 раунде 3 пользователя делают пэинт - выигрывает банк цвета (2 color)
        
        1 пользователь краской 2 (2 раза)
        2 пользователь краской 1 (2 раза) 
        4 пользователь краской 3 (1 раз) и краской 2 (1 раз)
        хардкод (9998) - время не должно выйти 
        5 пользователь краской 3 (1 раз) и краской 2 (1 раз)
        должен разыграться банк цвета
        
    проверить после 2 раунда:
        currentRound = 3
        withdrawalBalances[user1] = 2x
        withdrawalBalances[user2] = 3x
        withdrawalBalances[user3] = 0x
        withdrawalBalances[user4] = 3x
        withdrawalBalances[user5] = 1x
        
    */

contract("Time Bank Tests", async accounts => {
  //create new smart contract instance before each test method
  beforeEach(async function() {
    gameMock = await GameMock.deployed();
    user1 = accounts[1];
    user2 = accounts[2];
    user3 = accounts[3];
    user4 = accounts[4];
    user5 = accounts[5];
  });

  /*
  
    в 1 раунде 5 пользователей делают пэинт - выигрывает банк времени (1 color)
    
        1 пользователь краской 1 (5 раз)
        2 пользователь краской 2 (3 раза) и краской 3 (3 раза)
        3 пользователь краской 1 (3 раза)
        4 пользователь краской 2 (2 раза)
        хардкод (9998) - проходит время и банк цвета не должен разыграться
        5 пользователь краской 1 (1 раз) 
        ...проходят 20 минут
        5 пользователь краской 3 (1 раз (не должно засчитаться)) - последним (выигрывает банк времени)

  */

  it("1 round", async () => {
    currentRound = await gameMock.currentRound.call();

    console.log("\nCurrent round:", currentRound.toNumber());

    //1 пользователь краской 1 (5 раз)
    pixels = [1, 2, 3, 4, 5];
    color = 1;

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

    //3 пользователь краской 1 (3 раза)
    pixels = [12, 13, 14];
    color = 1;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user3, value: callPrice });
    console.log("user3 is painting pixels 12-14 with color", color);

    //4 пользователь краской 2 (2 раза)
    pixels = [15, 16];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user4, value: callPrice });
    console.log("user4 is painting pixels 15-16with color", color);

    //хардкод

    await gameMock.hardCode();

    //5 пользователь краской 1 (1 раз)
    pixels[17];
    color = 1;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, {
      from: user5,
      value: callPrice
    });

    console.log("user5 is painting pixel 17 with color", color);

    timeBank = await gameMock.timeBankForRound(currentRound);
    colorBank = await gameMock.colorBankForRound(currentRound);

    console.log("\n================================================\n");
    console.log(
      "Time bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(timeBank.toNumber())
    );

    console.log(
      "Color bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(colorBank.toNumber())
    );
    console.log("\n================================================\n");

    //20 minutes have passed
    const advancement = 20 * 60; //20 minutes
    await helper.advanceTimeAndBlock(advancement);
    console.log("20 minutes have passed by...\n");

    //5 пользователь краской 3 должен разыграться банк времени и начаться 2 раунд
    pixels = [18];
    color = 3;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, {
      from: user5,
      value: callPrice
    });
    console.log("user5 is painting pixel 18 with color", color); //проверить цвет этого пикселя в новос каррент раунде

    let total = await gameMock.colorToUserToTotalCounter(3, user5);

    let winnerBankForRound = await gameMock.winnerBankForRound(currentRound);
    if (total == 1 && winnerBankForRound == 1)
      console.log("Time Bank has been played in round", +currentRound);

    currentRound = await gameMock.currentRound.call();
    assert.equal(+currentRound, 2);
  });

  /*

   во 2 раунде 3 пользователя делают пэинт - выигрывает банк цвета (2 color)
        
        1 пользователь краской 2 (2 раза)
        2 пользователь краской 1 (2 раза) 
        4 пользователь краской 3 (1 раз) и краской 2 (1 раз)
        хардкод (9998) - время не должно выйти 
        5 пользователь краской 3 (1 раз) и краской 2 (1 раз)
        должен начаться 3 раунд и разыграться банк цвета для 2 раунда
    
  */

  it("2 round", async () => {
    currentRound = await gameMock.currentRound.call();
    console.log("\nCurrent round:", currentRound.toNumber());

    timeBank = await gameMock.timeBankForRound(currentRound);
    colorBank = await gameMock.colorBankForRound(currentRound);

    console.log("\n================================================\n");
    console.log(
      "Time bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(timeBank.toNumber())
    );

    console.log(
      "Color bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(colorBank.toNumber())
    );
    console.log("\n================================================\n");

    //1 пользователь краской 2 (2 раза)
    pixels = [1, 2];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user1, value: callPrice });
    console.log("user1 is painting pixels 1,2 with color", color);

    //2 пользователь краской 1 (2 раза) )
    pixels = [3, 4];
    color = 1;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user2, value: callPrice });
    console.log("user2 is painting pixels 3, 4 with color", color);

    //4 пользователь краской 3 (1 раз) и краской 2 (1 раз)
    pixels = [5];
    color = 3;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user4, value: callPrice });
    console.log("user4 is painting pixel 5 with color", color);

    pixels = [6];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user4, value: callPrice });
    console.log("user4 is painting pixel 6 with color", color);

    //хардкод

    await gameMock.hardCode2();
    console.log("hardcoding..."); //9998

    //5 пользователь краской 3 (1 раз) и краской 2 (2 разa)

    pixels = [7];
    color = 3;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user5, value: callPrice });
    console.log("user5 is painting pixel 7 with color", color);

    let round = await gameMock.lastPlayedRound(user5);
    console.log("***Last played round for user 5:", round.toNumber());

    pixels = [8];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user5, value: callPrice });
    console.log("user5 is painting pixel 8 with color", color);

    round = await gameMock.lastPlayedRound(user5);
    console.log("***Last played round for user 5:", round.toNumber());

    pixels = [9];
    color = 2;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user5, value: callPrice });
    console.log("user5 is painting pixel 8 with color", color);

    timeBank = await gameMock.timeBankForRound(currentRound);
    colorBank = await gameMock.colorBankForRound(currentRound);
    currentRound = await gameMock.currentRound();

    console.log("\n================================================\n");
    console.log(
      "**Time bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(timeBank.toNumber())
    );

    console.log(
      "Color bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(colorBank.toNumber())
    );
    console.log("\n================================================\n");

    round = await gameMock.lastPlayedRound(user5);
    console.log("Last played round for user 5:", round.toNumber());

    let winnerBank = await gameMock.winnerBankForRound(round);
    console.log("Winner bank:", winnerBank.toNumber());

    currentRound = await gameMock.currentRound.call();
    console.log("Current round:", currentRound.toNumber());

    //должно засчитаться за след раунд
    pixels = [11];
    color = 1;
    callPrice = await gameMock.estimateCallPrice(pixels, color);
    await gameMock.paint(pixels, color, { from: user5, value: callPrice });
    console.log("\nuser5 is painting pixel 11 with color", color);
  });

  /*
    проверить после 2 раунда:
        currentRound = 3
        withdrawalBalances[user1] = 2x
        withdrawalBalances[user2] = 3x
        withdrawalBalances[user3] = 0x
        withdrawalBalances[user4] = 3x
        withdrawalBalances[user5] = 1x
  */

  it("3 round", async () => {
    currentRound = await gameMock.currentRound.call();
    console.log("\nCurrent round:", currentRound.toNumber());

    timeBank = await gameMock.timeBankForRound(currentRound);
    colorBank = await gameMock.colorBankForRound(currentRound);

    console.log("\n================================================\n");
    console.log(
      "Time bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(timeBank.toNumber())
    );

    console.log(
      "Color bank of round",
      currentRound.toNumber(),
      "is",
      web3.fromWei(colorBank.toNumber())
    );
    console.log("\n================================================\n");

    let prize1 = await gameMock.addressToColorBankPrizeForRound(1, user3);
    let prize2 = await gameMock.addressToColorBankPrizeForRound(2, user3);
    let prize3 = await gameMock.addressToColorBankPrizeForRound(3, user3);
    let pri = await gameMock.addressToTimeBankPrizeTotal(user4);

    console.log("\nPrize 1 round for user5:", +prize1);
    console.log("\nPrize 2 round for user5:", +prize2);
    console.log("\nPrize 3 round for user5:", +prize3);
    console.log("\n Prize: ", +pri);
  });
});
