pragma solidity ^0.4.24;
import "../StorageV1.sol";

contract GameMock is StorageV1 {

    function mock() external {
        timeBankForRound[currentRound] = 1 ether;
        colorBankForRound[currentRound] = 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = totalPixelsNumber - 2;
    }

    function mock2() external {
        timeBankForRound[currentRound] += 1 ether;
        colorBankForRound[currentRound] += 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = totalPixelsNumber - 2;
    }

    function mock3(uint _winnerColor) external {
        colorToPaintedPixelsAmountForRound[currentRound][_winnerColor] = totalPixelsNumber - 2;
    }

    function mockMaxPaintsInPool() external {
        maxPaintsInPool = 100; 
        for (uint i = 1; i <= totalColorsNumber; i++) {
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
        }
    }
}