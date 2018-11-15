pragma solidity ^0.4.24;
import "./Safemath.sol";

//переписать все мат.операции с использованием Safemath

contract Generation {
    using SafeMath for uint;
    mapping (uint => uint) public totalPaintsForRound;
    uint public currentRound;
    mapping (uint => uint) public paintGenerationToAmount;
    mapping (uint => uint) public paintGenerationToStartTime;
    mapping (uint => uint) public paintGenerationToEndTime;
    uint public paintGeneration;
    mapping (uint => bool) public genStarted;
    mapping (uint => uint) public genToPrice;
    uint public callPrice;
    uint public maxPaints;
    
    function updateCallPrice() internal {
        callPrice = callPrice.mul(105).div(100);
        genToPrice[paintGeneration + 1] = callPrice;
    }
    
    constructor() public {
        maxPaints = 10;
        currentRound = 1;
        paintGeneration = 1;
        callPrice = 100 wei;
        genToPrice[paintGeneration] = callPrice;
        paintGenerationToAmount[paintGeneration] = maxPaints; //их 10000 единиц
    }
    
    function paint() external payable {
        require(msg.value == callPrice);
        if (totalPaintsForRound[currentRound] == 0) { //если ни одна ед краски еще не потрачена
            genStarted[paintGeneration] = true;
            paintGenerationToStartTime[paintGeneration] = now;
            paintGenerationToEndTime[paintGeneration - 1] = now;
        }
        
        if (now - paintGenerationToEndTime[paintGeneration - 1] >= 15 seconds) { //если прошло 1,5 минуты с момента посл
            uint paintsRemain = paintGenerationToAmount[paintGeneration]; //сколько краски остается в поколении
            
            uint newGeneration = paintGeneration.add(1); //новое поколение (2)
                
            if (genStarted[newGeneration] == false) {
                paintGenerationToAmount[newGeneration] = maxPaints.sub(paintsRemain); //cколько краски нового поколения создалось
                paintGenerationToStartTime[newGeneration] = now; //новое поколение создалось сейчас
                genStarted[newGeneration] = true;
            }
            
            if (paintGenerationToAmount[paintGeneration] == 1)
                updateCallPrice();
            
            if (paintGenerationToAmount[paintGeneration] == 0) {
                paintGenerationToEndTime[paintGeneration] = now;
                paintGeneration = newGeneration;
            }
        }
        
        paintGenerationToAmount[paintGeneration]--; //с каждым закрашиванием декреминтируем на 1 ед краски
        totalPaintsForRound[currentRound]++;
    }
}
