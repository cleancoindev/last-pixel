pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IColor.sol";
import "./Roles.sol";

contract DividendsDistributor is Roles {
    
    using SafeMath for uint;
    
    // Color color = Color(0x7899946bc29f3ab7443903bcc03e8a38407bb44a);
    
    mapping (uint => address) public ownerOfColor;
    
    constructor() {

        // for (uint i = 1; i < color.totalSupply(); i++) {
        //     ownerOfColor[i] = color.ownerOf(i);
        // }0xbF0e4036BF968dD007F9B4A1BFdA4e54C042F612

        for (uint i = 1; i <= 8; i++) {
            ownerOfColor[i] = 0xbF0e4036BF968dD007F9B4A1BFdA4e54C042F612;
        }
    }
    
    //балансы доступные для вывода (накопленный пассивный доход за все раунды)
    mapping (address => uint) public withdrawalBalances; 
    
    //время последнего вывода пассивного дохода для адреса для любого раунда (адрес => время)
    mapping (address => uint) addressToLastWithdrawalTime; 
    
    //банк пассивных доходов
    uint public dividendsBank;
    
    event DividendsWithdrawn(address indexed withdrawer, uint indexed claimId, uint indexed amount);
    event DividendsClaimed(address indexed claimer, uint indexed claimId, uint indexed currentTime);

    struct Claim {
        uint id;
        address claimer;
        bool isResolved;
        uint timestamp;
    }

    uint public claimId;
    Claim[] public claims;
  
    function claimDividends() external {
        //функция не может быть вызвана, если баланс для вывода пользователя равен нулю
        require(withdrawalBalances[msg.sender] != 0, "Your withdrawal balance is zero...");
        claimId = claimId.add(1);
        Claim memory c;
        c.id = claimId;
        c.claimer = msg.sender;
        c.isResolved = false;
        c.timestamp = now;
        claims.push(c);
        emit DividendsClaimed(msg.sender, claimId, now);
    }

    function approveClaim(uint _claimId) public onlyAdmin() {
        
        Claim storage claim = claims[_claimId];
        
        require(!claim.isResolved);
        
        address claimer = claim.claimer;

        //Checks-Effects-Interactions pattern
        uint withdrawalAmount = withdrawalBalances[claimer];

        //обнуляем баланс для вывода для пользователя
        withdrawalBalances[claimer] = 0;

        //перевести пользователю баланс для вывода
        claimer.transfer(withdrawalAmount);
        
        //устанавливаем время последнего вывода средств для пользователя
        addressToLastWithdrawalTime[claimer] = now;
        emit DividendsWithdrawn(claimer, _claimId, withdrawalAmount);

        claim.isResolved = true;
    }

     // захардкоженные адреса для тестирования функции claimDividens()
    // в продакшене это будут адреса бенефециариев Цветов и Пикселей : withdrawalBalances[ownerOf(_pixel)], withdrawalBalances[ownerOf(_color)]
    //address public ownerOfColor = 0xf106a93c5ca900bfae6345b61fcfae9d75cb031d;
    address public ownerOfPixel = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    address public founders = 0x3e4d187df7d8a0820eaf4174d17b160157610912;
   
    //функция распределения дивидендов (пассивных доходов) - будет работать после подключения инстансов контрактов Цвета и Пикселя
    function _distributeDividends(uint _color) internal {
        
        //require(ownerOfColor[_color] != address(0), "There is no such color");

        //25% дивидендов распределяем организаторам (может быть смарт контракт)
        withdrawalBalances[founders] = withdrawalBalances[founders].add(dividendsBank.mul(25).div(100)); 
    
        //25% дивидендов распределяем бенефециарию цвета
        withdrawalBalances[ownerOfColor[_color]] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем бенефециарию пикселя
        withdrawalBalances[ownerOfPixel] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем реферреру, если он есть
        // withdrawalBalances[referrer] += dividendsBank.mul(25).div(100);
    }
}