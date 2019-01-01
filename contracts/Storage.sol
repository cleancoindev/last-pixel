pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Storage {
    
    //сколько всего было разукрашиваний в этом раунде любым цветом
    mapping (uint => uint) public totalPaintsForRound; 

    //цвет клетки в раунде (pаунд => пиксель => цвет)
    mapping (uint => mapping (uint => uint)) public pixelToColorForRound; 

    //предыдущий цвет клетки в раунде (pаунд => пиксель => цвет)
    mapping (uint => mapping (uint => uint)) public pixelToOldColorForRound; 

    //маппинг цвета на количество клеток закрашенных этим цветом за раунд (раунд => цвет => количество пикселей)
    mapping (uint => mapping (uint => uint)) public colorToPaintedPixelsAmountForRound; 

    //банк цвета за раунд (раунд => банк цвета)
    mapping (uint => uint) public colorBankForRound; 

    //банк цвета для отдельного цвета за раунд (раунд => цвет => банк цвета)
    mapping (uint => mapping (uint => uint)) public colorBankToColorForRound; 

    //банк времени за раунд (раунд => банк времени)
    mapping (uint => uint) public timeBankForRound; 
    
    //время самого последнего закрашивания игрового поля за раунд (раунд => таймстэмп)
    mapping (uint => uint) public lastPaintTimeForRound; 

    //последний закрасивший любой пиксель пользователь за раунд (раунд => адрес)
    mapping (uint => address) public lastPainterForRound; 

    //последний разукрашенный пиксель за раунд
    mapping (uint => uint) public lastPaintedPixelForRound;

    //цвет который выиграл (которым заполнились все пиксели) за раунд (раунд => цвет) 
    mapping (uint => uint) public winnerColorForRound; 

    //значение общего количества разукрашиваний данным цветом за весь раунд (раунд => цвет => количество разукрашиваний)
    mapping (uint => mapping (uint => uint)) public colorToTotalPaintsForRound; 

    //счетчик общего количества закрашенных конкретным цветом клеток для пользователя (цвет => адрес => количество клеток)
    mapping(uint => mapping (address => uint)) public colorToUserToTotalCounter; 

    //счетчик общего количества закрашиваний любым цветом для пользователя(адрес => количество клеток)                                                                        
    mapping (address => uint) public userToTotalCounter;      

    //победитель раунда (раунд => адрес)
    mapping (uint => address) public winnerOfRound; 

    //банк который был разыгран в раунде (раунд => разыгранный банк) (1 = банк времени, 2 = банк цвета)
    mapping (uint => uint) public winnerBankForRound; 

    //последний раунд в котором пользователь принимал участие (адрес => раунд)
    mapping (address => uint) public lastPlayedRound; 

    //время закрашивания для каждого пикселя за раунд (0 = не закрашено)
    mapping (uint => mapping (uint => uint)) public pixelToPaintTimeForRound;

    //текущий раунд
    uint public currentRound;

    uint public tbIteration;
    uint public cbIteration;
    uint public paintsCounter; //счетчик закрашиваний любым цветом за все время
    //Time Bank Iteration => Painter => Painter's Share in Time Team
    mapping (uint => mapping (address => uint)) public timeBankShare;
    //Color Bank Iteration => Color => Painter => Painter's Share in Time Team
    mapping (uint => mapping (uint => mapping (address => uint))) public colorBankShare;
    mapping (uint => uint) public paintsCounterForColor; //счетчик закрашиваний конкретным цветом за все время
    mapping (uint => address[]) public cbTeam; //for cbIteration
    mapping (uint => address[]) public tbTeam; //for tbIteration
    mapping (uint => address) public counterToPainter; //cчетчик => пользователь
    mapping (uint => mapping (uint => address)) public counterToPainterForColor; //цвет => cчетчик => пользователь    
    mapping (uint => mapping (address => bool)) public isInCBT; //for cbIteration !should not be public
    mapping (uint => mapping (address => uint)) public painterToCBP; //cbIteration => painter => color bank prize
    mapping (uint => mapping (address => uint)) public painterToTBP; //tbIteration => painter => time bank prize

    mapping (uint => bool) public isCBPTransfered;
    mapping (uint => bool) public isTBPTransfered;

}