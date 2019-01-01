pragma solidity ^0.4.24;

import "./Storage.sol";

contract TimeBankDistributor is Storage {
    
    using SafeMath for uint;
    
    //сколько всего банка времени выиграл адрес (в сумме за все время) (адрес => сумма общего выигрыша)
    mapping(address => uint) public addressToTimeBankPrizeTotal; 

    
    event TimeBankPlayed(address indexed winner, uint indexed currentRound);
    event TimeBankPrizeDistributed(address indexed winner, uint indexed round, uint indexed amount);
    
   
    //функция распределения банка времени
    function _distributeTimeBank() internal  {

        //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];
        
         //Checks-Effects-Interactions pattern
        uint amountToTransfer = timeBankForRound[currentRound].mul(45).div(100);

        //переводим 45% банка времени победителю текущего раунда
        winnerOfRound[currentRound].transfer(amountToTransfer);
                
        //разыгранный банк этого раунда = банк времени (1)
        winnerBankForRound[currentRound] = 1; 

        //10% банка времени переходит в следующий раунд
        timeBankForRound[currentRound + 1] = timeBankForRound[currentRound].div(10); 
        
        //45% банка времени распределится между всей командой участников раунда
        timeBankForRound[currentRound] = timeBankForRound[currentRound].mul(45).div(100); 

        //банк цвета переносится на следующий раунд
        colorBankForRound[currentRound + 1] = colorBankForRound[currentRound]; 

        //в этом раунде банк цвета обнуляется
        colorBankForRound[currentRound] = 0; 

        //ивент - был разыгран банк времени (победитель, раунд)
        emit TimeBankPlayed(winnerOfRound[currentRound], currentRound);
        
        //следующий раунд
        currentRound = currentRound.add(1); 
    }
}