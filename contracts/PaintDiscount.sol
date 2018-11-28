pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract PaintDiscount  {
    
    using SafeMath for uint;
    
    //общее количество денег потраченных пользователем на покупку краски данного цвета
    mapping (uint => mapping (address => uint)) public moneySpentByUserForColor;
    
    //маппинг хранящий булевое значение о том, имеет ли пользователь какую либо скидку на покупку краски определенного цвета
    mapping (uint => mapping (address => bool)) public hasPaintDiscountForColor;
    
    //скидка пользователя на покупку краски определенного цвета (в процентах)
    mapping (uint => mapping (address => uint)) public usersPaintDiscountForColor;
    
    //функция сохраняющая скидку на покупку краски определенного цвета для пользователя
    function _setUsersPaintDiscountForColor(uint _color) internal {
        
        //за каждый потраченный 1 ETH даем скидку 1%
        usersPaintDiscountForColor[_color][msg.sender] = moneySpentByUserForColor[_color][msg.sender] / 1 ether;
        
        //максимальная скидка может равняться 10%
        if (moneySpentByUserForColor[_color][msg.sender] > 10 ether)
            usersPaintDiscountForColor[_color][msg.sender] = 10;
        
    }
    
    //функция сохраняющая общюю сумму потраченную пользователем на покупку краски определенного цвета за все время
    function _setMoneySpentByUserForColor(uint _color) internal {
        
        moneySpentByUserForColor[_color][msg.sender] += msg.value;

        if (moneySpentByUserForColor[_color][msg.sender] >= 1 ether)
            hasPaintDiscountForColor[_color][msg.sender] = true;
    }
    

    
}