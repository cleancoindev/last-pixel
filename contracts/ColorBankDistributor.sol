pragma solidity ^0.4.24;
import "./RoundDataHolder.sol";
import "./SafeMath.sol";

contract ColorBankDistributor is RoundDataHolder  {
    
    using SafeMath for uint;
    
    //сколько всего банка цвета выиграл адрес (в сумме за все время) (адрес => сумма общего выигрыша)
    mapping(address => uint) public addressToColorBankPrizeTotal; 
    
    event ColorBankPlayed(address indexed winner, uint indexed winnerColor, uint indexed currentRound);
    event ColorBankPrizeDistributed(address indexed winner, uint indexed round, uint indexed amount);
    
    //запросить приз банка цвета за послений раунд в котором пользователь принимал участие
    function claimColorBankPrizeForLastPlayedRound() public {

        //последний раунд в котором пользователь принимал участие
        uint round = lastPlayedRound[msg.sender];

        //функция может быть вызвана только если в последнем раунде был разыгран банк цвета
        require(lastPlayedRound[msg.sender] > 0 && winnerBankForRound[round] == 2, "Bank of color was not played in your last round...");

        //выигрышый цвет за последний раунд в котором пользователь принимал участие
        uint winnerColor = winnerColorForRound[round];

        //время завершения сбора команды приза для раунда
        uint end = teamEndedTimeForRound[round];

        //время начала сбора команды приза для раунда
        uint start = teamStartedTimeForRound[round];

        //cчетчик количества закрашиваний
        uint counter;
        
        //счетчик общего количества закрашиваний выигрышным цветом для пользователя за раунд     
        uint total = colorToAddressToTotalCounterForRound[round][winnerColor][msg.sender]; 

         //считаем сколько закрашиваний выигрышным цветом произвел пользователь за последние 24 часа
        for (uint i = total; i > 0; i--) {
            uint timeStamp = addressToColorToCounterToTimestampForRound[round][msg.sender][winnerColor][i];
            if (timeStamp > start && timeStamp <= end)
                counter = counter.add(1);
        }

        //устанавливаем какую часть от банка цвета выиграл адрес за последний раунд в котором принимал участие
        addressToColorBankPrizeForRound[round][msg.sender] += counter.mul(colorBankForRound[round]).div(colorToTotalPaintsForRound[round][winnerColor]);

        //добавляем полученное значение в сумму выигрышей банка цвета пользователем за все время
        addressToColorBankPrizeTotal[msg.sender] += addressToColorBankPrizeForRound[round][msg.sender];

         //переводим пользователю его выигрыш за последний раунд в котором он принимал участие
        msg.sender.transfer(addressToColorBankPrizeForRound[round][msg.sender]);

        //устанавливаем булевое значение о том, что пользователь получил свой приз за раунд
        isPrizeDistributedForRound[msg.sender][round] = true;

        //вызываем ивент - о том, что приз банка цвета распределен пользователю (адрес, раунд, выигрыш)
        emit ColorBankPrizeDistributed(msg.sender, round, addressToColorBankPrizeForRound[round][msg.sender]);
    }
    
    //функция распределения банка цвета
    function _distributeColorBank() internal { 

        //время начала сбора команды раунда (24 часа назад)
        teamStartedTimeForRound[currentRound] = now - 24 hours;

        //время завершения сбора команды раунда (сейчас)
        teamEndedTimeForRound[currentRound] = now;

        //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];
        
        //Checks-Effects-Interactions pattern
        uint amountToTransfer = colorBankForRound[currentRound].mul(50).div(100);
    
        //переводим 50% банка цвета победителю текущего раунда
        winnerOfRound[currentRound].transfer(amountToTransfer);
               
        //разыгранный банк этого раунда = банк цвета (2)
        winnerBankForRound[currentRound] = 2;

        //50% банка цвета распределится между командой цвета раунда
        colorBankForRound[currentRound] = colorBankForRound[currentRound].mul(50).div(100); 

        //банк времени переносится на следующий раунд
        timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];

        //банк времени в текущем раунде обнуляется
        timeBankForRound[currentRound] = 0;

        //ивент - был разыгран банк времени (победитель, победивший цвет раунд)
        emit ColorBankPlayed(winnerOfRound[currentRound], winnerColorForRound[currentRound], currentRound);
        
        //следующий раунд
        currentRound = currentRound.add(1); 
    }
}