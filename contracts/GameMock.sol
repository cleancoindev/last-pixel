pragma solidity ^0.4.24;
import "./Game.sol";

contract GameMock is Game {

    //функция обновления цены вызова функции закрашивания (paint)
    function _updateCallPrice(uint _color) private {
        
        //увеличиваем цену вызова на 5% (используем для отображения на фронте)
        nextCallPriceForColor[_color] = callPriceForColor[_color].mul(105).div(100);
        
        //вызываем ивент о том, что цена вызова функции paint обновлена
        emit CallPriceUpdated(callPriceForColor[_color]);
    }

    function hardCode() external {
        timeBankForRound[currentRound] = 1 ether;
        colorBankForRound[currentRound] = 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = 9998;
    }

    function hardCode2() external {
        timeBankForRound[currentRound] += 1 ether;
        colorBankForRound[currentRound] += 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = 9998;
    }

}