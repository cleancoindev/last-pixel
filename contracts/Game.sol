pragma solidity ^0.4.24;
import "openzeppelin-solidity/math/SafeMath.sol";
import "./tokens/Pixel.sol";

contract Game {
    using SafeMath for uint;
    
    mapping (uint => uint) public pixelToColor; // цвет клетки
    mapping (uint => uint) public pixelToOldColor; // предыдущий цвет клетки
    uint totalColors = 9; // сколько всего цветов. Изначально = 9, 0 = бесцветный
    mapping (uint => uint) public colorIdToPaintedPixelsAmount; //маппинг цвета на количество клеток закрашенных этим цветом
    mapping (address => uint) public withdrawalBalances; //балансы доступные для вывода (накопленный пассивный доход)
    uint public colorBank; //банк цвета
    uint public timeBank; //банк времени
    uint public dividendsBank; //банк дивидендов - общих пассивных доходов
    uint public lastPaintTime; //время самой последней закраски игрового поля
    address public lastPainter; //  последний закрасивший пользователь 
    uint public winnerColor; //цвет который выиграл (заполнились все пиксели данным цветом) //изначально =0, поэтому нужно проверить не помешает ли это
    
    function setHardcodedValues() external payable {
        colorIdToPaintedPixelsAmount[1] = 9998; //hardcode
        colorBank = 0.4 ether;
    }
    
    function paint(uint _pixelId, uint _colorId) external payable {
        require(_pixelId != 0, "The pixel with id = 0 does not exist...");
        require(msg.value == 10 finney, "This function call costs 0.01 eth..."); //0.01 ETH
        require(_colorId != 0, "You cannot paint to transparent color.."); //нельзя перекрасить в бесцветный
        require(pixelToOldColor[_pixelId] != _colorId, "Cannot paint to the same color as it was"); //cannot paint pixel to the same coloe twice
        
        if (now - lastPaintTime > 20 minutes) {
            timeBank = timeBank.div(10);
            newGame(); //обнуляет все счетчики, заполняет краски и клетки
            distributeTimeBank();
            msg.sender.transfer(msg.value); //возвращаем средства пользователя назад, так как этот раунд закончился
        }
        colorBank = colorBank.add(4 finney);
        timeBank = timeBank.add(4 finney);
        dividendsBank = dividendsBank.add(2 finney); //увеличиваем значение суммы дивидендов для выплаты пассивного дохода
        
        uint oldColorId = pixelToColor[_pixelId];
        
        pixelToColor[_pixelId] = _colorId; //перекрашиваем в новый цвет
        pixelToOldColor[_pixelId] = oldColorId; //cохраняем предыдущий цвет в маппинге
        lastPaintTime = now; //время последней раскраски во всем игровом поле
        lastPainter = msg.sender; // самый последний разукрасивший участник на всем игромвом поле
        
        if (colorIdToPaintedPixelsAmount[oldColorId] > 0) //если счетчик старого цвета положительный, уменьшаем его значение
            colorIdToPaintedPixelsAmount[oldColorId] = colorIdToPaintedPixelsAmount[oldColorId].sub(1); 
        colorIdToPaintedPixelsAmount[_colorId] = colorIdToPaintedPixelsAmount[_colorId].add(1); //при каждой раскраске клетки, увеличиваем счетчик цвета

        //счетчик общего количества закрашенных конкретным цветом клеток для пользователя
        uint totalCounterForUser = colorIdToAddressToTotalCounter[_colorId][msg.sender]; 
        totalCounterForUser = totalCounterForUser.add(1); //увеличиваем счетчик количества закрашенных конкретным цветом клеток для пользователя
        colorIdToAddressToTotalCounter[_colorId][msg.sender] = totalCounterForUser; //обновляем значения общего кол-ва закрашенных пользователем данным цветом клеток
        addressToColorIdToCounterToTimestamp[msg.sender][_colorId][totalCounterForUser] = now;
        colorIdToTotalPaints[_colorId] = colorIdToTotalPaints[_colorId].add(1); //увеличиваем значение общего количества разукрашиваний данным цветом (для всего раунда)
        
        if (colorIdToPaintedPixelsAmount[_colorId] == 10000) { //если все поле (10000 пикселей) заполнилось одним цветом
            winnerColor = _colorId;
            lastPainter.transfer(colorBank.mul(50).div(100)); //перевести половину банка цвета последнему закрасившему
            colorIdToPaintedPixelsAmount[_colorId] = 0;//сбросить количество клеток закрашенных этим цветом на бесцветный - работает неправильно
            colorBank = 0 ether;
            //обнулить все pixelToColor[_pixelId] либо создать новый маппинг
        }
    }
    
    mapping (uint => uint) public colorIdToTotalPaints; //значение общего количества разукрашиваний данным цветом (для всего раунда)
    mapping (uint => mapping (address => uint)) public colorIdToAddressToTotalCounter; // счетчик общего количества закрашенных конкретным цветом клеток для пользователя
                                                                                                  //напр. Всего красную краску Боб использовал 89 раз
    
    mapping (address => mapping (uint => mapping (uint => uint))) public addressToColorIdToCounterToTimestamp; //адрес => цвет краски => счетчик => метка времени
                                                                                      //напр. Боб использовал зеленую краску в 65-ый раз на 165934 блоке
    
    function claimColorBankPrize() external { 
        uint totalCounterForUser = colorIdToAddressToTotalCounter[winnerColor][msg.sender];
        uint lastTimestamp = addressToColorIdToCounterToTimestamp[msg.sender][winnerColor][totalCounterForUser];
        require(now - lastTimestamp <= 24 hours); // проверяем красил ли пользователь данным цветом в течение последних 24 часов
        uint counter;
        while ((now - lastTimestamp) <= 24 hours) {
            counter.add(1); //инкрементируем
            totalCounterForUser.sub(1); //декреминтируем 
            lastTimestamp = addressToColorIdToCounterToTimestamp[msg.sender][winnerColor][totalCounterForUser]; // обновляем значение последней метки
        }
        uint amountToTransfer = counter.mul(colorBank).div(colorIdToTotalPaints[winnerColor]); //делить на общее число разукрашиваний этим цветом
        msg.sender.transfer(amountToTransfer);
    }
    
    function distributeTimeBank() private {
        
    }
    
    function claimDividends() external canClaimDividends {
        require(withdrawalBalances[msg.sender] != 0);
        msg.sender.transfer(withdrawalBalances[msg.sender]);
        addressToLastWithdrawalTime[msg.sender] = now;
    }
    
    function newGame() private {
        //oldColorId = 0;
        //о
        /* 
        бнулить все счетчики 
        cоздать новый маппинг
        Возможно имеет смысл для этого создать новый инстанс контракта игры и передать просто в банк времени и дивидендов значения со старой игры
        
        */
    }

    uint dividendsTime = 3 days; // время через которое можно запрашивать пассивный доход
    mapping (address => uint) addressToLastWithdrawalTime; // время последнего вывода пассивного дохода для адреса
    
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