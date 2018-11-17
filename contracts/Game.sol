pragma solidity ^0.4.24;
import "openzeppelin-solidity/math/SafeMath.sol";
import "openzeppelin-solidity/ownership/Ownable.sol";

contract Game is Ownable {

    using SafeMath for uint;

    //время последнего вывода пассивного дохода для адреса для любого раунда (адрес => время)
    mapping (address => uint) addressToLastWithdrawalTime; 

    //сколько всего было разукрашиваний в этом раунде любым цветом
    mapping (uint => uint) public totalPaintsForRound; 

    //цвет клетки в раунде (pаунд => пиксель => цвет)
    mapping (uint => mapping (uint => uint)) public pixelToColorForRound; 

    //предыдущий цвет клетки в раунде (pаунд => пиксель => цвет)
    mapping (uint => mapping (uint => uint)) public pixelToOldColorForRound; 

    //маппинг цвета на количество клеток закрашенных этим цветом за раунд (раунд => цвет => количество пикселей)
    mapping (uint => mapping (uint => uint)) public colorToPaintedPixelsAmountForRound; 

    //балансы доступные для вывода (накопленный пассивный доход за все раунды)
    mapping (address => uint) public withdrawalBalances; 

    //банк цвета за раунд (раунд => банк цвета)
    mapping (uint => uint) public colorBankForRound; 

    //банк времени за раунд (раунд => банк времени)
    mapping (uint => uint) public timeBankForRound; 
    
    //время самого последнего закрашивания игрового поля за раунд (раунд => таймстэмп)
    mapping (uint => uint) public lastPaintTimeForRound; 

    //последний закрасивший любой пиксель пользователь за раунд (раунд => адрес)
    mapping (uint => address) public lastPainterForRound; 

    //цвет который выиграл (которым заполнились все пиксели) за раунд (раунд => цвет) 
    mapping (uint => uint) public winnerColorForRound; 

    //значение общего количества разукрашиваний данным цветом за весь раунд (раунд => цвет => количество разукрашиваний)
    mapping (uint => mapping (uint => uint)) public colorToTotalPaintsForRound; 

    //время начала образования команды банка за раунд (раунд => время)
    mapping(uint => uint) public teamStartedTimeForRound;

    //время завершения команды банка за раунд (раунд => время)
    mapping(uint => uint) public teamEndedTimeForRound;
    
    //счетчик общего количества закрашенных конкретным цветом клеток для пользователя за раунд (раунд => цвет => адрес => количество клеток)
    mapping (uint => mapping(uint => mapping (address => uint))) public colorToAddressToTotalCounterForRound; 

    //счетчик общего количества закрашиваний любым цветом для пользователя за раунд (раунд => адрес => количество клеток)                                                                        
    mapping(uint => mapping (address => uint)) public addressToTotalCounterForRound;

    //время использования краски определенного цвета в n-ый по счету раз для пользователя за раунд (адрес => цвет краски => счетчик => метка времени)                                                                                      
    mapping (uint => mapping(address => mapping (uint => mapping (uint => uint)))) public addressToColorToCounterToTimestampForRound; 
                                                                            
    //время использования краски любого цвета в n-ый по счету раз для пользователя за раунд (адрес => счетчик => метка времени)                                                                    
    mapping(uint=>mapping(address=>mapping(uint=>uint))) public addressToCounterToTimestampForRound; 

    //булевое значение проверяет получил ли пользователь приз банка за раунд (адрес => раунд => булевое значение)                                                                            
    mapping(address => mapping(uint => bool)) public isPrizeDistributedForRound;
    
    //последний раунд в котором пользователь принимал участие (адрес => раунд)
    mapping (address => uint) public lastPlayedRound; 
    
    //приз банка цвета для пользователя за раунд (раунд => адрес => выигрыш)
    mapping(uint => mapping(address => uint)) public addressToColorBankPrizeForRound; 

    //приз банка времени для пользователя за раунд (раунд => адрес => выигрыш)
    mapping(uint => mapping(address => uint)) public addressToTimeBankPrizeForRound; 

    //сколько всего банка цвета выиграл адрес (в сумме за все время) (адрес => сумма общего выигрыша)
    mapping(address => uint) public addressToColorBankPrizeTotal; 

    //сколько всего банка времени выиграл адрес (в сумме за все время) (адрес => сумма общего выигрыша)
    mapping(address => uint) public addressToTimeBankPrizeTotal; 

    //победитель раунда (раунд => адрес)
    mapping (uint => address) public winnerOfRound; 

    //банк который был разыгран в раунде (раунд => разыгранный банк) (1 = банк времени, 2 = банк цвета)
    mapping (uint => uint) public winnerBankForRound; 
    
    //поколение краски на ее количество
    mapping (uint => uint) public paintGenToAmount;
    
    //время когда краска определенного поколения добавилась в пул
    mapping (uint => uint) public paintGenToStartTime;
    
    //время когда краска определенного поколения закончилась в пуле
    mapping (uint => uint) public paintGenToEndTime;
    
    //булевое значение - о том что, поколение краски началось
    mapping (uint => bool) public paintGenStarted;
    
    //цена поколения краски
    mapping (uint => uint) public paintGenToPrice;

    //текущее поколение краски которое расходуется в данный момент
    uint public currentPaintGen;
    
    //стоимость вызова функции paint
    uint public callPrice;
    
    //количество единиц краски в общем пуле (10000)
    uint public maxPaintsInPool;

    //банк пассивных доходов
    uint public dividendsBank;

    //текущий раунд
    uint public currentRound;

    //ивенты
    event ColorBankPlayed(address indexed winner, uint indexed winnerColor, uint indexed currentRound);
    event TimeBankPlayed(address indexed winner, uint indexed currentRound);
    event Paint(uint indexed pixelId, uint indexed colorId, address indexed painter);
    event ColorBankPrizeDistributed(address indexed winner, uint indexed round, uint indexed amount);
    event TimeBankPrizeDistributed(address indexed winner, uint indexed round, uint indexed amount);
    event DividendsWithdrawn(address indexed withdrawer, uint indexed currentBlock, uint indexed amount);
    event CallPriceUpdated(uint indexed newCallPrice);
    
    //конструктор, задающий изначальные значения переменных
    constructor() public payable { 
        maxPaintsInPool = 10; //10000 in production
        currentRound = 1;
        currentPaintGen = 1;
        callPrice = 100 wei; //0.01 ETH in production
        paintGenToPrice[currentPaintGen] = callPrice;
        paintGenToAmount[currentPaintGen] = maxPaintsInPool;
        paintGenStarted[currentPaintGen] = true;
        paintGenToStartTime[currentPaintGen] = now;
    }
    
    //возвращает цвет пикселя в этом раунде
    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }
    
    //функция закрашивания пикселя цветом
    function paint(uint _pixel, uint _color) external payable {
        
        //устанавливаем значения для краски в пуле и цену вызова функции paint
        _fillPaintsPool();
        
        require(msg.value == callPrice, "Wrong call price...");
        require(_pixel != 0, "The pixel with id = 0 does not exist...");
        require(_color != 0, "You cannot paint to transparent color...");
        require(pixelToColorForRound[currentRound][_pixel] != _color, "This pixel is already of this color...");
        
        //проверяем не прошло ли 20 минут с последней раскраски для розыгрыша банка времени
        if (now - lastPaintTimeForRound[currentRound] > 20 minutes && lastPaintTimeForRound[currentRound] != 0) {

            //распределяем банк времени команде раунда
            _distributeTimeBank();
        }
        
        else {

            //распределяем ставку по банкам
            _setBanks();
            
            //распределяем дивиденды (пассивный доход) бенефециариам
            _distributeDividends();
            
            //красим пиксель заданным цветом
            _paint(_pixel, _color);
            
            //проверяем не закрасилось ли все игровое поле данным цветом для розыгрыша банка цвета
            if (colorToPaintedPixelsAmountForRound[currentRound][_color] == 10000) {

                //цвет победивший в текущем раунде
                winnerColorForRound[currentRound] = _color;

                //распределяем банк цвета команде цвета
                _distributeColorBank();                
            }

            //при каждом закрашивании, требуем приз за предыдущий раунд, если он был
            _claimBankPrizeForLastPlayedRound();

            //ивент - закрашивание пикселя (пиксель, цвет, закрасивший пользователь)
            emit Paint(_pixel, _color, msg.sender);          
        }
    }

    //запросить приз банка времени за послений раунд в котором пользователь принимал участие
    function claimTimeBankPrizeForLastPlayedRound() public { 

        //последний раунд в котором пользователь принимал участие
        uint round = lastPlayedRound[msg.sender];

        //функция может быть вызвана только если в последнем раунде был разыгран банк времени
        require(lastPlayedRound[msg.sender] > 0 && winnerBankForRound[round] == 1, "Bank of time was not played in your last round...");

        //время завершения сбора команды приза для раунда
        uint end = teamEndedTimeForRound[round];

        //время начала сбора команды приза для раунда
        uint start = teamStartedTimeForRound[round];

        //cчетчик количества закрашиваний
        uint counter;
        
        //счетчик общего количества закрашиваний любым цветом для пользователя за раунд     
        uint total = addressToTotalCounterForRound[round][msg.sender]; 

        //считаем сколько закрашиваний любым цветом произвел пользователь за последние 24 часа
        for (uint i = total; i > 0; i--) {
            uint timeStamp = addressToCounterToTimestampForRound[round][msg.sender][i];
            if (timeStamp > start && timeStamp <= end) //т.к. (<= end), то последний закрасивший также принимает участие
                counter++;
        }
        
        //устанавливаем какую часть от банка времени выиграл адрес за последний раунд в котором принимал участие
        addressToTimeBankPrizeForRound[round][msg.sender] += counter.mul(timeBankForRound[round]).div(totalPaintsForRound[round]);

        //добавляем полученное значение в сумму выигрышей банка времени пользователем за все время
        addressToTimeBankPrizeTotal[msg.sender] += addressToTimeBankPrizeForRound[round][msg.sender];
        
        //переводим пользователю его выигрыш за последний раунд в котором он принимал участие
        msg.sender.transfer(addressToTimeBankPrizeForRound[round][msg.sender]);

        //устанавливаем булевое значение о том, что пользователь получил свой приз за раунд
        isPrizeDistributedForRound[msg.sender][round] = true;

        //вызываем ивент - о том, что приз банка времени распределен пользователю (адрес, раунд, выигрыщ)
        emit TimeBankPrizeDistributed(msg.sender, round, addressToColorBankPrizeForRound[round][msg.sender]);
    }
    
    //запросить приз банка цвета за послений раунд в котором пользователь принимал участие
    function claimColorBankPrizeForLastPlayedRound() public {

        //последний раунд в котором пользователь принимал участие
        uint round = lastPlayedRound[msg.sender];

        //функция может быть вызвана только если в последнем раунде был разыгран банк цвета
        require(lastPlayedRound[msg.sender] > 0 && winnerBankForRound[round] == 2, "Bank of color was not played in your last round...");

        //выигрышый цвет за последний раунд в котором пользователь принимал участие
        uint winnerColor = winnerColorForRound[round];

        //время завершения сбора команды приза для раунда
        uint end = teamEndedTimeForRound[round];

        //время начала сбора команды приза для раунда
        uint start = teamStartedTimeForRound[round];

        //cчетчик количества закрашиваний
        uint counter;
        
        //счетчик общего количества закрашиваний выигрышным цветом для пользователя за раунд     
        uint total = colorToAddressToTotalCounterForRound[round][winnerColor][msg.sender]; 

         //считаем сколько закрашиваний выигрышным цветом произвел пользователь за последние 24 часа
        for (uint i = total; i > 0; i--) {
            uint timeStamp = addressToColorToCounterToTimestampForRound[round][msg.sender][winnerColor][i];
            if (timeStamp > start && timeStamp <= end)
                counter = counter.add(1);
        }

        //устанавливаем какую часть от банка цвета выиграл адрес за последний раунд в котором принимал участие
        addressToColorBankPrizeForRound[round][msg.sender] += counter.mul(colorBankForRound[round]).div(colorToTotalPaintsForRound[round][winnerColor]);

        //добавляем полученное значение в сумму выигрышей банка цвета пользователем за все время
        addressToColorBankPrizeTotal[msg.sender] += addressToColorBankPrizeForRound[round][msg.sender];

         //переводим пользователю его выигрыш за последний раунд в котором он принимал участие
        msg.sender.transfer(addressToColorBankPrizeForRound[round][msg.sender]);

        //устанавливаем булевое значение о том, что пользователь получил свой приз за раунд
        isPrizeDistributedForRound[msg.sender][round] = true;

        //вызываем ивент - о том, что приз банка цвета распределен пользователю (адрес, раунд, выигрыш)
        emit ColorBankPrizeDistributed(msg.sender, round, addressToColorBankPrizeForRound[round][msg.sender]);
    }
    
    //функция запроса вывода дивидендов (пассивного дохода)
    function claimDividends() external {

        //функция не может быть вызвана, если баланс для вывода пользователя равен нулю
        require(withdrawalBalances[msg.sender] != 0, "Your withdrawal balance is zero...");

        //перевести пользователю баланс для вывода
        msg.sender.transfer(withdrawalBalances[msg.sender]);
        
        //устанавливаем время последнего вывода средств для пользователя
        addressToLastWithdrawalTime[msg.sender] = now;
        
        //вызываем ивент о том, что дивиденды выплачены (адрес, время вывода, количество вывода)
        emit DividendsWithdrawn(msg.sender, now, withdrawalBalances[msg.sender]);
        
        //обнуляем баланс для вывода для пользователя
        withdrawalBalances[msg.sender] = 0;
    }

    //нужно для тестирования, убрать в продакшене
    function setHardcodedValues() external payable {
        colorToPaintedPixelsAmountForRound[currentRound][2] = 9992;
        colorBankForRound[currentRound] = 0.2 ether;
        timeBankForRound[currentRound] = 0.2 ether;
    }   

    //основная логика закрашивания пикселя цветом
    function _paint(uint _pixel, uint _color) private {

        //берем предыдущий цвет данного пикселя
        uint oldColor = pixelToColorForRound[currentRound][_pixel];

        //перекрашиваем в новый цвет
        pixelToColorForRound[currentRound][_pixel] = _color; 

        //cохраняем предыдущий цвет в маппинге
        pixelToOldColorForRound[currentRound][_pixel] = oldColor; 
            
        //время последнего закрашивания во всем игровом поле в этом раунде
        lastPaintTimeForRound[currentRound] = now; 

        //самый последний разукрасивший пользователь на всем игровом поле в этом раунде
        lastPainterForRound[currentRound] = msg.sender;
            
        //если счетчик старого цвета положительный, уменьшаем его значение
        if (colorToPaintedPixelsAmountForRound[currentRound][oldColor] > 0) 
            colorToPaintedPixelsAmountForRound[currentRound][oldColor] = colorToPaintedPixelsAmountForRound[currentRound][oldColor].sub(1); 

        //при каждой раскраске пикселя, увеличиваем счетчик цвета
        colorToPaintedPixelsAmountForRound[currentRound][_color] = colorToPaintedPixelsAmountForRound[currentRound][_color].add(1); 
    
        //счетчик общего количества закрашенных конкретным цветом клеток для пользователя за текущий раунд
        uint totalCounterToColorForUserForRound = colorToAddressToTotalCounterForRound[currentRound][_color][msg.sender]; 

        //увеличиваем счетчик количества закрашенных конкретным цветом клеток для пользователя
        totalCounterToColorForUserForRound = totalCounterToColorForUserForRound.add(1); 

        //обновляем значения общего кол-ва закрашенных пользователем данным цветом клеток для пользователя за текущий раунд в маппинге
        colorToAddressToTotalCounterForRound[currentRound][_color][msg.sender] = totalCounterToColorForUserForRound; 
            
        //счетчик общего количества закрашенных любым цветом клеток для пользователя за текущий раунд
        uint totalCounterForUserForRound = addressToTotalCounterForRound[currentRound][msg.sender]; 

        //увеличиваем счетчик количества закрашенных любым цветом клеток для пользователя за текущий раунд
        totalCounterForUserForRound = totalCounterForUserForRound.add(1); 

        //обновляем значение общего количества закрашенных любым цветом клеток для пользователя за текущий раунд в маппинге
        addressToTotalCounterForRound[currentRound][msg.sender] = totalCounterForUserForRound;
            
        // устанавливаем время закрашивания конкретным цветом в n-ый раз для пользователя за текущий раунд
        addressToColorToCounterToTimestampForRound[currentRound][msg.sender][_color][totalCounterToColorForUserForRound] = now;

        // устанавливаем время закрашивания любым цветом в n-ый раз для пользователя за текущий раунд
        addressToCounterToTimestampForRound[currentRound][msg.sender][totalCounterForUserForRound] = now;
            
        //увеличиваем значение общего количества разукрашиваний данным цветом для всего раунда
        colorToTotalPaintsForRound[currentRound][_color] = colorToTotalPaintsForRound[currentRound][_color].add(1); 

        //увеличиваем значение общего количества разукрашиваний любым цветом для всего раунда
        totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(1); 

        //устанавливаем значение последнего сыгранного раунда для пользователя равным текущему раунду
        lastPlayedRound[msg.sender] = currentRound;
            
        //с каждым закрашиванием декреминтируем на 1 ед краски
        paintGenToAmount[currentPaintGen] = paintGenToAmount[currentPaintGen].sub(1);
    }

    //функция распределения ставки
    function _setBanks() private {

        //40% ставки идет в банк цвета
        colorBankForRound[currentRound] = colorBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //40% ставки идет в банк времени
        timeBankForRound[currentRound] = timeBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //20% ставки идет на пассивные доходы бенефециариев
        dividendsBank = dividendsBank.add(msg.value.mul(20).div(100)); 
    }

    //функция распределения банка цвета
    function _distributeColorBank() private { 

        //время начала сбора команды раунда (24 часа назад)
        teamStartedTimeForRound[currentRound] = now - 24 hours;

        //время завершения сбора команды раунда (сейчас)
        teamEndedTimeForRound[currentRound] = now;

        //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];

        //переводим 50% банка цвета победителю текущего раунда
        winnerOfRound[currentRound].transfer(colorBankForRound[currentRound].mul(50).div(100));
               
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
    
    //функция распределения банка времени
    function _distributeTimeBank() private  {

        //начало сбора команды раунда (24 часа назад)
        teamStartedTimeForRound[currentRound] = now - 24 hours;

        //время завершения сбора команды раунда (сейчас)
        teamEndedTimeForRound[currentRound] = now;

        //победитель текущего раунда - последний закрасивший пиксель пользователь за этот раунд
        winnerOfRound[currentRound] = lastPainterForRound[currentRound];

        //переводим 45% банка времени победителю текущего раунда
        winnerOfRound[currentRound].transfer(timeBankForRound[currentRound].mul(45).div(100));
                
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
    
    //запросить приз за послений раунд в котором пользователь принимал участие
    function _claimBankPrizeForLastPlayedRound() private {

        //если пользователь еще не получил приз за участие в последнем раунде
        if (lastPlayedRound[msg.sender] > 1 && isPrizeDistributedForRound[msg.sender][lastPlayedRound[msg.sender]] == false) {
                
            //если был разыгран банк времени
            if(winnerBankForRound[lastPlayedRound[msg.sender]] == 1) 
                //выдать приз банка времени за последний раунд в котором принимал участие пользователь
                claimTimeBankPrizeForLastPlayedRound();

            //если был разыгран банк времени
            if(winnerBankForRound[lastPlayedRound[msg.sender]] == 2) 
                //выдать приз банка цвета за последний раунд в котором принимал участие пользователь
                claimColorBankPrizeForLastPlayedRound();
        }      

    }

    //функция обновления цены вызова функции закрашивания (paint)
    function _updateCallPrice() private {

        //увеличиваем цену вызова на 5%
        callPrice = callPrice.mul(105).div(100);

        //задаем цену для следнующего поколения краски
        paintGenToPrice[currentPaintGen + 1] = callPrice;
    }
    
    //функция пополнения пула краски
    function _fillPaintsPool() private {
        
        //если ни одна единица краски еще не потрачена
        if (totalPaintsForRound[currentRound] == 0) {
            paintGenToEndTime[currentPaintGen - 1] = now;
        }
        
        //каждые полторы минуты пул дополняется новой краской
        if (now - paintGenToEndTime[currentPaintGen - 1] >= 15 seconds) { 
            
            //сколько краски остается в поколении
            uint paintsRemain = paintGenToAmount[currentPaintGen]; 
            
            //следующее поколение краски
            uint nextPaintGen = currentPaintGen.add(1); 
            
            //если прошло полторы минуты и след. поколение краски все еще не создано     
            if (paintGenStarted[nextPaintGen] == false) {
                
                //создаем новое поколение краски на недостающее количество единиц
                paintGenToAmount[nextPaintGen] = maxPaintsInPool.sub(paintsRemain); 
                
                //новое поколение создалось сейчас
                paintGenToStartTime[nextPaintGen] = now; 

                paintGenStarted[nextPaintGen] = true;
            }
            
            //как только не осталось краски текущего поколения
            if (paintGenToAmount[currentPaintGen] == 0) {
                
                //обновляем цену вызова закрашивания краской следующего поколения
                _updateCallPrice();

                //вызываем ивент о том, что цена вызова функции paint обновлена
                emit CallPriceUpdated(callPrice);
                
                //краска текущего поколения закончилась сейчас
                paintGenToEndTime[currentPaintGen] = now;

                //переходим на использование следующего поколения краски
                currentPaintGen = nextPaintGen;
            }
        }
    }

    // захардкоженные адреса для тестирования функции claimDividens()
    // в продакшене это будут адреса бенефециариев Цветов и Пикселей : withdrawalBalances[ownerOf(_pixel)], withdrawalBalances[ownerOf(_color)]
    address ownerOfColor = 0xf106a93c5ca900bfae6345b61fcfae9d75cb031d;
    address ownerOfPixel = 0x5ac77c56772a1819663ae375c9a2da2de34307ef;
    
    //функция распределения дивидендов (пассивных доходов) - будет работать после подключения инстансов контрактов Цвета и Пикселя
    function _distributeDividends() private {

        //25% дивидендов распределяем организаторам (может быть смарт контракт)
        withdrawalBalances[owner()] = withdrawalBalances[owner()].add(dividendsBank.mul(25).div(100)); 
    
        //25% дивидендов распределяем бенефециарию цвета
        withdrawalBalances[ownerOfColor] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем бенефециарию пикселя
        withdrawalBalances[ownerOfPixel] += dividendsBank.mul(25).div(100);
    
        //25% дивидендов распределяем реферреру, если он есть
        // withdrawalBalances[referrer] += dividendsBank.mul(25).div(100);
    }

}