pragma solidity ^0.4.24;
import "openzeppelin-solidity/math/SafeMath.sol";

contract Game {

    using SafeMath for uint;

    uint totalColors = 9; // сколько всего цветов. Изначально = 9, 0 = бесцветный
    uint public currentRound = 1; 
    uint public currentTime;
    uint dividendsTime = 3 days; // время через которое можно запрашивать пассивный доход

    mapping (address => uint) addressToLastWithdrawalTime; // время последнего вывода пассивного дохода для адреса для любого раунда
    mapping (uint => uint) public totalPaintsForRound; //сколько всего было разукрашиваний в этом раунде любым цветом
    mapping (uint => mapping (uint => uint)) public pixelToColorForRound; // цвет клетки
    mapping (uint => mapping (uint => uint)) public pixelToOldColorForRound; // предыдущий цвет клетки
    mapping (uint => mapping (uint => uint)) public colorToPaintedPixelsAmountForRound; //маппинг цвета на количество клеток закрашенных этим цветом
    mapping (address => uint) public withdrawalBalances; //балансы доступные для вывода (накопленный пассивный доход за все раунды)
    mapping (uint => uint) public colorBankForRound; //банк цвета
    mapping (uint => uint) public timeBankForRound; //банк времени
    //mapping (uint => uint) public dividendsBankForRound; //банк дивидендов - общих пассивных доходов
    uint public dividendsBank;
    mapping (uint => uint) public lastPaintTimeForRound; //время самой последней закраски игрового поля
    mapping (uint => address) public lastPainterForRound; //  последний закрасивший пользователь 
    mapping (uint => uint) public winnerColorForRound; //цвет который выиграл (заполнились все пиксели данным цветом) 
    mapping (uint => mapping (uint => uint)) public colorToTotalPaintsForRound; //значение общего количества разукрашиваний данным цветом (для всего раунда)
    mapping(uint => uint) public startedTimeForRound;
    mapping(uint => uint) public finishedTimeForRound;
    
    //1//
    mapping (uint => mapping(uint => mapping (address => uint))) public colorToAddressToTotalCounterForRound; // счетчик общего количества закрашенных конкретным цветом клеток для пользователя
                                                                                                  //напр. Всего красную краску Боб использовал 89 раз
    mapping(uint => mapping (address => uint)) public addressToTotalCounterForRound; // счетчик общего кол-ва закрашиваний любым цветом для адреса за этот                                                                              
                                                                                      
    //2//                                                                                         
    mapping (uint => mapping(address => mapping (uint => mapping (uint => uint)))) public addressToColorToCounterToTimestampForRound; //адрес => цвет краски => счетчик => метка времени
                                                                                      //напр. Боб использовал зеленую краску в 65-ый раз на 165934 блоке
                                                                            
    mapping(uint=>mapping(address=>mapping(uint=>uint))) public addressToCounterToTimestampForRound; 
                                                                                      
    mapping(address => mapping(uint => bool)) public isPrizeDistributedForRound;
    
    mapping (address => uint) public lastPlayedRound; //последний раунд в котором юзер принимал участие
    
    //3////счетчик разукрашиваний ..
    mapping(uint=>mapping(address=>mapping(uint=>mapping(uint=>uint)))) public addressToColorToTimestampToCounterForRound;
    mapping(uint=>mapping(address=>mapping(uint=>uint))) public addressToTimestampToCounterForRound;
    
    mapping(uint => mapping(address => uint)) public addressToColorBankPrizeForRound;
    mapping(uint => mapping(address => uint)) public addressToTimeBankPrizeForRound;
    mapping(address => uint) public addressToColorBankPrizeTotal;
    mapping(address => uint) public addressToTimeBankPrizeTotal;
    mapping (uint => address) public winnerOfRound;
    
    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }
    
    function setHardcodedValues() external payable {
        //colorToPaintedPixelsAmountForRound[currentRound][1] = 9998; //hardcode
        timeBankForRound[currentRound] = 0.2 ether;
        //lastPaintTime = now - 25 minutes;
        currentTime = now;
    }   
    
    function getCurTime() external view  returns (uint) {
        return now;
    }
    
    function paint(uint _pixel, uint _color) external payable {
        require(_pixel != 0, "The pixel with id = 0 does not exist...");
        //require(msg.value == 10 finney, "This function call costs 0.01 eth..."); //0.01 ETH
        require(_color != 0, "You cannot paint to transparent color.."); //нельзя перекрасить в бесцветный
        require(pixelToColorForRound[currentRound][_pixel] != _color, "Cannot paint to the same color as it was"); //cannot paint pixel to the same coloe twice
        currentTime = now;   
        
        if (now - lastPaintTimeForRound[currentRound] > 1 minutes && lastPaintTimeForRound[currentRound] != 0) { //в продакшене это будет 20 минут
            startedTimeForRound[currentRound] = now - 24 hours; //когда начался момент для сбора команды а не сам раунд
            finishedTimeForRound[currentRound] = now;
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];
            winnerOfRound[currentRound].transfer(timeBankForRound[currentRound].mul(45).div(100));
            distributeTimeBank();
            msg.sender.transfer(msg.value); //возвращаем средства пользователя назад, так как этот раунд закончился
        }
        else {
            colorBankForRound[currentRound] = colorBankForRound[currentRound].add(4 finney);
            timeBankForRound[currentRound] = timeBankForRound[currentRound].add(4 finney);
            dividendsBank = dividendsBank.add(2 finney); //увеличиваем значение суммы дивидендов для выплаты пассивного дохода
            
            uint oldColor = pixelToColorForRound[currentRound][_pixel];
            
            pixelToColorForRound[currentRound][_pixel] = _color; //перекрашиваем в новый цвет
            pixelToOldColorForRound[currentRound][_pixel] = oldColor; //cохраняем предыдущий цвет в маппинге
            lastPaintTimeForRound[currentRound] = now; //время последней раскраски во всем игровом поле
            lastPainterForRound[currentRound] = msg.sender; // самый последний разукрасивший участник на всем игромвом поле
            
            if (colorToPaintedPixelsAmountForRound[currentRound][oldColor] > 0) //если счетчик старого цвета положительный, уменьшаем его значение
                colorToPaintedPixelsAmountForRound[currentRound][oldColor] = colorToPaintedPixelsAmountForRound[currentRound][oldColor].sub(1); 
            colorToPaintedPixelsAmountForRound[currentRound][_color] = colorToPaintedPixelsAmountForRound[currentRound][_color].add(1); //при каждой раскраске клетки, увеличиваем счетчик цвета
    
            //счетчик общего количества закрашенных конкретным цветом клеток для пользователя
            uint totalCounterToColorForUser = colorToAddressToTotalCounterForRound[currentRound][_color][msg.sender]; 
            totalCounterToColorForUser = totalCounterToColorForUser.add(1); //увеличиваем счетчик количества закрашенных конкретным цветом клеток для пользователя
            colorToAddressToTotalCounterForRound[currentRound][_color][msg.sender] = totalCounterToColorForUser; //обновляем значения общего кол-ва закрашенных пользователем данным цветом клеток
            
            //счетчик общего количества закрашенных любым цветом клеток для пользователя
            uint totalCounterForUserForRound = addressToTotalCounterForRound[currentRound][msg.sender]; //для любого цвета
            totalCounterForUserForRound = totalCounterForUserForRound.add(1); //увеличиваем счетчик количества закрашенных любым цветом клеток для пользователя
            addressToTotalCounterForRound[currentRound][msg.sender] = totalCounterForUserForRound;
            
            addressToColorToCounterToTimestampForRound[currentRound][msg.sender][_color][totalCounterToColorForUser] = now;
            addressToCounterToTimestampForRound[currentRound][msg.sender][totalCounterForUserForRound] = now;
            
            
            addressToColorToTimestampToCounterForRound[currentRound][msg.sender][_color][now]++;
            addressToTimestampToCounterForRound[currentRound][msg.sender][now] = totalCounterForUserForRound;
            
            
            colorToTotalPaintsForRound[currentRound][_color] = colorToTotalPaintsForRound[currentRound][_color].add(1); //увеличиваем значение общего количества разукрашиваний данным цветом (для всего раунда)
            totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(1); //
            lastPlayedRound[msg.sender] = currentRound;
            
            if (colorToPaintedPixelsAmountForRound[currentRound][_color] == 10000) { //если все поле (10000 пикселей) заполнилось одним цветом
                
                startedTimeForRound[currentRound] = now - 24 hours; //когда начался момент для сбора команды
                finishedTimeForRound[currentRound] = now;
                
                winnerColorForRound[currentRound] = _color;
                winnerOfRound[currentRound] = lastPainterForRound[currentRound];
                winnerOfRound[currentRound].transfer(colorBankForRound[currentRound].mul(50).div(100));
                distributeColorBank(); //разыгрываем банк цвета
            }
            
            if (lastPlayedRound[msg.sender] > 1 && isPrizeDistributedForRound[msg.sender][lastPlayedRound[msg.sender]] == false) {
                //distributeColorBankPrizeForLastPlayedRound();
                distributeTimeBankPrizeForLastPlayedRound();
            }                
        }
    }
    
    function distributeColorBankPrizeForLastPlayedRound() public { //for the last played round should not be public or check that winnercolor != 0, this causes error
        require(lastPlayedRound[msg.sender] > 0);
        uint round = lastPlayedRound[msg.sender];
        uint winnerColor = winnerColorForRound[round];
        uint end = addressToColorToTimestampToCounterForRound[round][msg.sender][winnerColor][finishedTimeForRound[round]];
        uint start = addressToColorToTimestampToCounterForRound[round][msg.sender][winnerColor][startedTimeForRound[round]];
        uint counter = end - start;
        addressToColorBankPrizeForRound[round][msg.sender] += counter.mul( colorBankForRound[round]).div(colorToTotalPaintsForRound[round][winnerColor]);
        withdrawalBalances[msg.sender] += addressToColorBankPrizeForRound[round][msg.sender];
        addressToColorBankPrizeTotal[msg.sender] += addressToColorBankPrizeForRound[round][msg.sender];
        isPrizeDistributedForRound[msg.sender][round] = true;
        
    }
    
     function distributeTimeBankPrizeForLastPlayedRound() public { //for the last played round should not be public or check that winnercolor != 0, this causes error
        require(lastPlayedRound[msg.sender] > 0);
        uint round = lastPlayedRound[msg.sender];
        uint end = finishedTimeForRound[round];
        uint start = startedTimeForRound[round];
        uint counter;
        
        uint total = addressToTotalCounterForRound[round][msg.sender]; //20
            for (uint i = total; i > 0; i--) {
                uint timeStamp = addressToCounterToTimestampForRound[round][msg.sender][i];
                if (timeStamp > start && timeStamp < end)
                    counter++;
            }
            
        addressToTimeBankPrizeForRound[round][msg.sender] += counter.mul(timeBankForRound[round]).div(totalPaintsForRound[round]);
        withdrawalBalances[msg.sender] += addressToTimeBankPrizeForRound[round][msg.sender];
        addressToTimeBankPrizeTotal[msg.sender] += addressToTimeBankPrizeForRound[round][msg.sender];
        isPrizeDistributedForRound[msg.sender][round] = true;
        
    }
    
    function distributeColorBank() public { //should not be public
        colorBankForRound[currentRound] = colorBankForRound[currentRound].mul(50).div(100); //осталось для распределения
        timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];
        timeBankForRound[currentRound] = 0;
        finishedTimeForRound[currentRound] = now;
        currentRound = currentRound.add(1); 
    }
    
    function distributeTimeBank() public  {
        timeBankForRound[currentRound + 1] = timeBankForRound[currentRound].div(10); //переходит в след раунд
        timeBankForRound[currentRound] = timeBankForRound[currentRound].mul(45).div(100); //осталось для распределения
        colorBankForRound[currentRound + 1] = colorBankForRound[currentRound]; //банк цвета для след раунда
        colorBankForRound[currentRound] = 0; //в этом раунде нужно обнулить
        finishedTimeForRound[currentRound] = now;
        currentRound = currentRound.add(1); 
    }
    
    function claimDividends() external canClaimDividends {
        require(withdrawalBalances[msg.sender] != 0);
        msg.sender.transfer(withdrawalBalances[msg.sender]);
        addressToLastWithdrawalTime[msg.sender] = now;
        //hasWithdrawnOnRound[currentRound] = true;
    }

    modifier canClaimDividends() {
        require(now - addressToLastWithdrawalTime[msg.sender] > dividendsTime);
        _;
    }

    //это все будет работать после того как подключу инстансы NFT токенов пикселя и цвета, так как мне нужны функции ownerOf(NFT)
    // function distributeDividends() private {
    //     withdrawalBalances[owner] = withdrawalBalances[owner].add(dividendsBank.mul(25).div(100)); //25% организаторам (владельцу контракта)
    //     withdrawalBalances[ownerOf(_colorId)] += dividendsBank.mul(25).div(100);
    //     withdrawalBalances[ownerOf(_pixelId)] += dividendsBank.mul(25).div(100);
    //     withdrawalBalances[referrer] += dividendsBank.mul(25).div(100);
        
    // }

    
}