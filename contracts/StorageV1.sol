pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./StorageV0.sol";

contract StorageV1 is StorageV0 {

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

    //победитель раунда (раунд => адрес)
    mapping (uint => address) public winnerOfRound; 

    //банк который был разыгран в раунде (раунд => разыгранный банк) (1 = банк времени, 2 = банк цвета)
    mapping (uint => uint) public winnerBankForRound; 

    //время закрашивания для каждого пикселя за раунд (0 = не закрашено)
    mapping (uint => mapping (uint => uint)) public pixelToPaintTimeForRound;

    //сколько всего было разукрашиваний в этом раунде любым цветом
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
    
    //стоимость следующего вызова функции paint
    mapping (uint => uint) public nextCallPriceForColor;
    
    //общее количество денег потраченных пользователем на покупку краски данного цвета
    mapping (uint => mapping (address => uint)) public moneySpentByUserForColor;
    
    //маппинг хранящий булевое значение о том, имеет ли пользователь какую либо скидку на покупку краски определенного цвета
    mapping (uint => mapping (address => bool)) public hasPaintDiscountForColor;
    
    //скидка пользователя на покупку краски определенного цвета (в процентах)
    mapping (uint => mapping (address => uint)) public usersPaintDiscountForColor;

     //зарегистрированный пользователь
    mapping (address => bool) public isRegisteredUser;
    
    //пользователь имеет свою реферальную ссылку (аккредитованный для получения дивидендов рефера)
    mapping (address => bool) public hasRefLink;

    //маппинг реферала к реферу
    mapping (address => address) public referralToReferrer;

    //маппинг реферера к его рефералам
    mapping (address => address[]) public referrerToReferrals;
    
    //маппинг пользователя на наличие рефера
    mapping (address => bool) public hasReferrer;
    
    //маппинг пользователя к его реф ссылке
    mapping (address => string) public userToRefLink;
    
    //маппинг реф ссылки к пользователю - владельцу этой реф ссылки
    mapping (bytes32 => address) public refLinkToUser;
    
    //маппинг проверяющий существование (наличие в базе) реф ссылки
    mapping (bytes32 => bool) public refLinkExists;
    
    //маппинг пользователь к счетчику уникальных зарегистрированных пользователей 
    mapping (address => uint) public newUserToCounter;
    
    //счетчик уникальных пользователей
    uint public uniqueUsersCount;

    //количество единиц краски в общем пуле (10000)
    uint public maxPaintsInPool;

    //текущий раунд
    uint public currentRound;

    //итерация банка времени
    uint public tbIteration;

    //итерация банка цвета
    uint public cbIteration;

    //счетчик закрашиваний любым цветом за все время
    uint public paintsCounter; 

    //Time Bank Iteration => Painter => Painter's Share in Time Team
    mapping (uint => mapping (address => uint)) public timeBankShare;

    //Color Bank Iteration => Color => Painter => Painter's Share in Time Team
    mapping (uint => mapping (uint => mapping (address => uint))) public colorBankShare;

    //счетчик закрашиваний конкретным цветом за все время
    mapping (uint => uint) public paintsCounterForColor; 

    //cbIteration => команда цвета
    mapping (uint => address[]) public cbTeam; 

    //tbIteration => команда цвета
    mapping (uint => address[]) public tbTeam;

     //cчетчик => пользователь
    mapping (uint => address) public counterToPainter;

    //цвет => cчетчик => пользователь    
    mapping (uint => mapping (uint => address)) public counterToPainterForColor; 

    //cbIteration => пользователь !should not be public
    mapping (uint => mapping (address => bool)) public isInCBT; 

    //tbIteration => пользователь !should not be public
    mapping (uint => mapping (address => bool)) public isInTBT; 

    //cbIteration => painter => color bank prize
    mapping (uint => mapping (address => uint)) public painterToCBP; 

    //tbIteration => painter => time bank prize
    mapping (uint => mapping (address => uint)) public painterToTBP; 

    //сbIteration => булевое значение
    mapping (uint => bool) public isCBPTransfered;

    //tbIteration => булевое значент
    mapping (uint => bool) public isTBPTransfered;

    //последний раунд в котором пользователь принимал участие
    mapping (address => uint) public lastPlayedRound;
    
    //Dividends Distribution
    mapping (uint => address) public ownerOfColor;

     //балансы доступные для вывода (накопленный пассивный доход за все раунды)
    mapping (address => uint) public withdrawalBalances; 
    
    //время последнего вывода пассивного дохода для адреса для любого раунда (адрес => время)
    mapping (address => uint) addressToLastWithdrawalTime; 
    
    //банк пассивных доходов
    uint public dividendsBank;

    struct Claim {
        uint id;
        address claimer;
        bool isResolved;
        uint timestamp;
    }

    uint public claimId;
    Claim[] public claims;

    // захардкоженные адреса для тестирования функции claimDividens()
    // в продакшене это будут адреса бенефециариев Цветов и Пикселей : withdrawalBalances[ownerOf(_pixel)], withdrawalBalances[ownerOf(_color)]
    //address public ownerOfColor = 0xf106a93c5ca900bfae6345b61fcfae9d75cb031d;
    address public ownerOfPixel = 0xca35b7d915458ef540ade6068dfe2f44e8fa733c;
    address public founders = 0x3e4d187df7d8a0820eaf4174d17b160157610912;
    
    bool public isGamePaused;

}