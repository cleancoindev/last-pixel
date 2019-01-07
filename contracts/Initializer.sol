pragma solidity ^0.4.24;
import "./StorageV1.sol";

contract Initializer is StorageV1 {

    //constructors which should have been in any the implementation contract
    function _initializer() internal {

        isAdmin[msg.sender] = true;
        maxPaintsInPool = 10000; //10000 in production
        currentRound = 1;
        cbIteration = 1;
        tbIteration = 1;
        
        for (uint i = 1; i <= 8; i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 0.01 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
            paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
            
            //если ни одна единица краски еще не потрачена
            if (totalPaintsForRound[currentRound] == 0) {
                paintGenToEndTimeForColor[i][currentPaintGenForColor[i] - 1] = now;
            }
            
            paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
        }
        
    }
}