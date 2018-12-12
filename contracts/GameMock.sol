pragma solidity ^0.4.24;
import "./Game.sol";

contract GameMock is Game {
    constructor() payable {
        maxPaintsInPool = 100; //10000 in production
        currentRound = 1;
        
        for (uint i = 1; i <= 3; i++) {
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

    function currentTime() public view returns (uint) {
        return now;
    }

    function setPaintedPixelsAmount(uint _color, uint _amount) external {
        colorToPaintedPixelsAmountForRound[currentRound][_color] = _amount;
    }

    function setColorBankForRound(uint _round, uint _colorBank) external {
        colorBankForRound[_round] = _colorBank;
    }

    function setTimeBankForRound(uint _round, uint _timeBank) external {
        timeBankForRound[_round] = _timeBank;
    }

    function paint9998pixels(uint _color) external {
        colorToPaintedPixelsAmountForRound[currentRound][_color] = 9998;
        colorBankForRound[currentRound] = 2 ether; //just custom number
    }

    uint public colorBankPrizeOfLastPainter;

    //функция распределения банка цвета - overriden
    function _distributeColorBank() internal { 

        //время начала сбора команды раунда (24 часа назад)
        teamStartedTimeForRound[currentRound] = now - 24 hours;

        //время завершения сбора команды раунда (сейчас)
        teamEndedTimeForRound[currentRound] = now;

        //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];
        
        //Checks-Effects-Interactions pattern
        colorBankPrizeOfLastPainter = colorBankForRound[currentRound].mul(50).div(100);
    
        //переводим 50% банка цвета победителю текущего раунда
        winnerOfRound[currentRound].transfer(colorBankPrizeOfLastPainter);
               
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

    //функция обновления цены вызова функции закрашивания (paint)
    function _updateCallPrice(uint _color) private {
        
        //увеличиваем цену вызова на 5% (используем для отображения на фронте)
        nextCallPriceForColor[_color] = callPriceForColor[_color].mul(105).div(100);
        
        //вызываем ивент о том, что цена вызова функции paint обновлена
        emit CallPriceUpdated(callPriceForColor[_color]);
    }

    //функция пополнения пула краски
    function _fillPaintsPool(uint _color) internal {
        
        //каждые полторы минуты пул дополняется новой краской
        if (now - paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] >= 1.5 minutes) { 
            
            //сколько краски остается в поколении
            uint paintsRemain = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]]; 
            
            //следующее поколение краски
            uint nextPaintGen = currentPaintGenForColor[_color].add(1); 
            
            //если прошло полторы минуты и след. поколение краски все еще не создано     
            if (paintGenStartedForColor[_color][nextPaintGen] == false) {
                
                //создаем новое поколение краски на недостающее количество единиц
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool.sub(paintsRemain); 
                
                //новое поколение создалось сейчас
                paintGenToStartTimeForColor[_color][nextPaintGen] = now; 

                paintGenStartedForColor[_color][nextPaintGen] = true;
            }
            
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 1) {
                
                //обновляем цену вызова закрашивания краской следующего поколения
                _updateCallPrice(_color);
                
                //краска текущего поколения закончилась сейчас
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color]] = now;
            }
               
            //как только не осталось краски текущего поколения
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
                
                //цена вызова закрашивания краской текущего поколения
                callPriceForColor[_color] = nextCallPriceForColor[_color];

                //переходим на использование следующего поколения краски
                currentPaintGenForColor[_color] = nextPaintGen;
            }
        }
    }

    uint public timeBankPrizeOfLastPainter;

    //функция распределения банка времени
    function _distributeTimeBank() internal  {

        //начало сбора команды раунда (24 часа назад)
        teamStartedTimeForRound[currentRound] = now - 24 hours;

        //время завершения сбора команды раунда (сейчас)
        teamEndedTimeForRound[currentRound] = now;

        //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];
        
         //Checks-Effects-Interactions pattern
        timeBankPrizeOfLastPainter = timeBankForRound[currentRound].mul(45).div(100);

        //переводим 45% банка времени победителю текущего раунда
        winnerOfRound[currentRound].transfer(timeBankPrizeOfLastPainter);
                
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