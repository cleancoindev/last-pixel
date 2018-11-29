pragma solidity ^0.4.24;

import "./RoundDataHolder.sol";

contract TimeBankDistributor is RoundDataHolder {
    
    using SafeMath for uint;
    
    //сколько всего банка времени выиграл адрес (в сумме за все время) (адрес => сумма общего выигрыша)
    mapping(address => uint) public addressToTimeBankPrizeTotal; 

    
    event TimeBankPlayed(address indexed winner, uint indexed currentRound);
    event TimeBankPrizeDistributed(address indexed winner, uint indexed round, uint indexed amount);
    
    //запросить приз банка времени за послений раунд в котором пользователь принимал участие
    function claimTimeBankPrizeForLastPlayedRound() public { 

        //последний раунд в котором пользователь принимал участие
        uint round = lastPlayedRound[msg.sender];

        //функция может быть вызвана только если в последнем раунде был разыгран банк времени
        require(lastPlayedRound[msg.sender] > 0 && winnerBankForRound[round] == 1, "Bank of time was not played in your last round...");

        //время завершения сбора команды приза для раунда
        uint end = teamEndedTimeForRound[round];

        //время начала сбора команды приза для раунда
        uint start = teamStartedTimeForRound[round];

        //cчетчик количества закрашиваний
        uint counter;
        
        //счетчик общего количества закрашиваний любым цветом для пользователя за раунд     
        uint total = addressToTotalCounterForRound[round][msg.sender]; 

        //считаем сколько закрашиваний любым цветом произвел пользователь за последние 24 часа
        for (uint i = total; i > 0; i--) {
            uint timeStamp = addressToCounterToTimestampForRound[round][msg.sender][i];
            if (timeStamp > start && timeStamp <= end) //т.к. (<= end), то последний закрасивший также принимает участие
                counter++;
        }
        
        //устанавливаем какую часть от банка времени выиграл адрес за последний раунд в котором принимал участие
        addressToTimeBankPrizeForRound[round][msg.sender] += counter.mul(timeBankForRound[round]).div(totalPaintsForRound[round]);

        //добавляем полученное значение в сумму выигрышей банка времени пользователем за все время
        addressToTimeBankPrizeTotal[msg.sender] += addressToTimeBankPrizeForRound[round][msg.sender];
        
        //переводим пользователю его выигрыш за последний раунд в котором он принимал участие
        msg.sender.transfer(addressToTimeBankPrizeForRound[round][msg.sender]);

        //устанавливаем булевое значение о том, что пользователь получил свой приз за раунд
        isPrizeDistributedForRound[msg.sender][round] = true;

        //вызываем ивент - о том, что приз банка времени распределен пользователю (адрес, раунд, выигрыщ)
        emit TimeBankPrizeDistributed(msg.sender, round, addressToColorBankPrizeForRound[round][msg.sender]);
    }
    
    //функция распределения банка времени
    function _distributeTimeBank() internal  {

        //начало сбора команды раунда (24 часа назад)
        teamStartedTimeForRound[currentRound] = now - 24 hours;

        //время завершения сбора команды раунда (сейчас)
        teamEndedTimeForRound[currentRound] = now;

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

        //возвращаем средства пользователя назад, так как этот раунд завершен и закрашивание не засчиталось
        msg.sender.transfer(msg.value); 

        //ивент - был разыгран банк времени (победитель, раунд)
        emit TimeBankPlayed(winnerOfRound[currentRound], currentRound);
        
        //следующий раунд
        currentRound = currentRound.add(1); 
    }
}