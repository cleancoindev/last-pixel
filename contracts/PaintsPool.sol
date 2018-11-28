pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract PaintsPool  {
    
    using SafeMath for uint;
    
    mapping (uint => uint) public totalPaintsForRound;
        
     //поколение краски на ее количество
    mapping (uint => mapping (uint => uint)) public paintGenToAmountForColor;
    
    //время когда краска определенного поколения добавилась в пул
    mapping (uint => mapping (uint => uint)) public paintGenToStartTimeForColor;
    
    //время когда краска определенного поколения закончилась в пуле
    mapping (uint => mapping (uint => uint)) public paintGenToEndTimeForColor;
    
    //булевое значение - о том что, поколение краски началось
    mapping (uint => mapping (uint => bool)) public paintGenStartedForColor;

    //текущее поколение краски которое расходуется в данный момент
    mapping (uint => uint) public currentPaintGenForColor;
    
    //стоимость вызова функции paint
    mapping (uint => uint) public callPriceForColor;
    
    //количество единиц краски в общем пуле (10000)
    uint public maxPaintsInPool;
    
    event CallPriceUpdated(uint indexed newCallPrice);

    //функция обновления цены вызова функции закрашивания (paint)
    function _updateCallPrice(uint _color) private {
        
        //увеличиваем цену вызова на 5%
        callPriceForColor[_color] = callPriceForColor[_color].mul(105).div(100);
    }
    
    //функция пополнения пула краски
    function _fillPaintsPool(uint _color) internal {
        
        //каждые полторы минуты пул дополняется новой краской
        if (now - paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] >= 15 seconds) { 
            
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
            
            //как только не осталось краски текущего поколения
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
                
                //обновляем цену вызова закрашивания краской следующего поколения
                _updateCallPrice(_color);

                //вызываем ивент о том, что цена вызова функции paint обновлена
                emit CallPriceUpdated(callPriceForColor[_color]);
                
                //краска текущего поколения закончилась сейчас
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color]] = now;

                //переходим на использование следующего поколения краски
                currentPaintGenForColor[_color] = nextPaintGen;
            }
        }
    }
}