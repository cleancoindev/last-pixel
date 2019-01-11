pragma solidity ^0.4.24;
import "./StorageV1.sol";

contract GameMock is StorageV1 {

    function mock() external {
        timeBankForRound[currentRound] = 1 ether;
        colorBankForRound[currentRound] = 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = 9998;
    }

    function mock2() external {
        timeBankForRound[currentRound] += 1 ether;
        colorBankForRound[currentRound] += 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = 9998;
    }

    function mockMaxPaintsInPool() external {
        maxPaintsInPool = 100; 
        for (uint i = 1; i <= 8; i++) {
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
        }
    }
}