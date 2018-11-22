pragma solidity ^0.4.24;

import "./SafeMath.sol";

contract DividendsDistributor {
    
    using SafeMath for uint;
    
    //балансы доступные для вывода (накопленный пассивный доход за все раунды)
    mapping (address => uint) public withdrawalBalances; 
    
    //время последнего вывода пассивного дохода для адреса для любого раунда (адрес => время)
    mapping (address => uint) addressToLastWithdrawalTime; 
    
    //банк пассивных доходов
    uint public dividendsBank;
    
    event DividendsWithdrawn(address indexed withdrawer, uint indexed currentBlock, uint indexed amount);
    
    //функция запроса вывода дивидендов (пассивного дохода)
    function claimDividends() external {

        //функция не может быть вызвана, если баланс для вывода пользователя равен нулю
        require(withdrawalBalances[msg.sender] != 0, "Your withdrawal balance is zero...");

        //Checks-Effects-Interactions pattern
        uint withdrawalAmount = withdrawalBalances[msg.sender];

        //обнуляем баланс для вывода для пользователя
        withdrawalBalances[msg.sender] = 0;

        //перевести пользователю баланс для вывода
        msg.sender.transfer(withdrawalAmount);
        
        //устанавливаем время последнего вывода средств для пользователя
        addressToLastWithdrawalTime[msg.sender] = now;
        
        //вызываем ивент о том, что дивиденды выплачены (адрес, время вывода, количество вывода)
        emit DividendsWithdrawn(msg.sender, now, withdrawalAmount);
        
    }

    
     // захардкоженные адреса для тестирования функции claimDividens()
    // в продакшене это будут адреса бенефециариев Цветов и Пикселей : withdrawalBalances[ownerOf(_pixel)], withdrawalBalances[ownerOf(_color)]
    address ownerOfColor = 0xf106a93c5ca900bfae6345b61fcfae9d75cb031d;
    address ownerOfPixel = 0x5ac77c56772a1819663ae375c9a2da2de34307ef;
    address founders = 0x5ac77c56772a1819663ae375c9a2da2de34307ef;
    
    //функция распределения дивидендов (пассивных доходов) - будет работать после подключения инстансов контрактов Цвета и Пикселя
    function _distributeDividends() internal {

        //25% дивидендов распределяем организаторам (может быть смарт контракт)
        withdrawalBalances[founders] = withdrawalBalances[founders].add(dividendsBank.mul(25).div(100)); 
    
        //25% дивидендов распределяем бенефециарию цвета
        withdrawalBalances[ownerOfColor] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем бенефециарию пикселя
        withdrawalBalances[ownerOfPixel] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем реферреру, если он есть
        // withdrawalBalances[referrer] += dividendsBank.mul(25).div(100);
    }
}