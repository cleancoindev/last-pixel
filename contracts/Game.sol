
pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./DividendsDistributor.sol";
import "./TimeBankDistributor.sol";
import "./ColorBankDistributor.sol";
import "./RoundDataHolder.sol";
import "./PaintsPool.sol";
import "./PaintDiscount.sol";
import "./IColor.sol";

contract GameMult is Ownable, TimeBankDistributor, ColorBankDistributor, PaintsPool, PaintDiscount, DividendsDistributor  {

    using SafeMath for uint;
    
    //последний раунд в котором пользователь принимал участие (адрес => раунд)
    mapping (address => uint) public lastPlayedRound; 

    //общее количество уникальных пользователей
    uint public uniqueUsers;

    //маппинг на булевое значение о том, что пользователь зарегистрирован в системе (принимал участие в игре)
    mapping (address => bool) public isRegistered;
    
    //ивенты
    event Paint(uint indexed pixelId, uint  colorId, address indexed painter, uint indexed round);
   
    //конструктор, задающий изначальные значения переменных
    constructor() public payable { 
        
        maxPaintsInPool = 10000; //10000 in production
        currentRound = 1;
        
        for (uint i = 1; i <= 3; i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 0.01 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
            paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
            
            //если ни одна единица краски еще не потрачена
            if (totalPaintsForRound[currentRound] == 0) {
                paintGenToEndTimeForColor[i][currentPaintGenForColor[i] - 1] = now;
            }
            
            paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
        }
        
    }
    
    function hardCode() external {
        timeBankForRound[currentRound] = 1 ether;
        colorBankForRound[currentRound] = 1 ether;
        colorToPaintedPixelsAmountForRound[currentRound][2] = 9998;
    }
    
    //возвращает цвет пикселя в этом раунде
    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }
    
    modifier isRegisteredUser() {
        //если пользоваель ни разу не принимал участие в игре, инкрементируем значение уникальных пользователй
        if (isRegistered[msg.sender] == false) {
            isRegistered[msg.sender] = true;
            uniqueUsers = uniqueUsers.add(1);
        }
        _;
    }        
    
    //функция оценивающая сколько будет стоить функция закрашивания
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint) {
        
        uint price;
        uint discount;
        uint discountCallPrice;
        uint moneySpent;
        uint totalCallPrice;
        bool hasDiscount;
        

        moneySpent = moneySpentByUserForColor[_color][msg.sender];
        hasDiscount = hasPaintDiscountForColor[_color][msg.sender];
        discount = usersPaintDiscountForColor[_color][msg.sender];
       
        
        for (uint i = 0; i < _pixels.length; i++) {
            
            discountCallPrice = (nextCallPriceForColor[_color].mul(100 - discount)).div(100);
            
            if (hasDiscount == true) 
                price = discountCallPrice;
            else
                price = nextCallPriceForColor[_color]; 

            totalCallPrice += price;
            moneySpent += price;

            if (moneySpent >= 1 ether) {
                
                hasDiscount = true;
                discount = moneySpent / 1 ether;
                
                if (moneySpent >= 10 ether)
                    discount = 10;
            }
            
        }   
        
        return totalCallPrice;
    }
    

    function paint(uint[] _pixels, uint _color) external payable isRegisteredUser {

        require(msg.value == estimateCallPrice(_pixels, _color), "Wrong call price");
        
        //проверяем не прошло ли 20 минут с последней раскраски для розыгрыша банка времени
        if (now - lastPaintTimeForRound[currentRound] > 20 minutes && lastPaintTimeForRound[currentRound] != 0) {

            //распределяем банк времени команде раунда
            _distributeTimeBank();
        }
        
        //закрашиваем пиксели
        for(uint i = 0; i < _pixels.length; i++) {
            _paint(_pixels[i], _color);
        }
        
         //распределяем ставку по банкам
        _setBanks(_color);
            
        //распределяем дивиденды (пассивный доход) бенефециариам
        _distributeDividends(_color);
    
         //сохраняем значение потраченных пользователем денег на покупку краски данного цвета
        _setMoneySpentByUserForColor(_color); 
        
        //сохраняем значение скидки на покупку краски данного цвета для пользователя
        _setUsersPaintDiscountForColor(_color);

        //при каждом закрашивании, требуем приз за предыдущий раунд, если он был
        _claimBankPrizeForLastPlayedRound();

    }   

    //функция закрашивания пикселя цветом
    function _paint(uint _pixel, uint _color) internal {

        //устанавливаем значения для краски в пуле и цену вызова функции paint
        _fillPaintsPool(_color);

        require(_pixel != 0, "The pixel with id = 0 does not exist...");
        require(_color != 0, "You cannot paint to transparent color...");
        require(pixelToColorForRound[currentRound][_pixel] != _color, "This pixel is already of this color...");

        //paint    
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
        
        //счетчик общего количества закрашенных конкретным цветом клеток для пользователя 
        uint totalCounterToColorForUser = colorToUserToTotalCounter[_color][msg.sender]; 
    
        //увеличиваем счетчик количества закрашенных конкретным цветом клеток для пользователя
        totalCounterToColorForUser = totalCounterToColorForUser.add(1); 

        //обновляем значения общего кол-ва закрашенных пользователем данным цветом клеток для пользователя в маппинге
        colorToUserToTotalCounter[_color][msg.sender] = totalCounterToColorForUser; 
                
        //счетчик общего количества закрашенных любым цветом клеток для пользователя
        uint totalCounterForUser = userToTotalCounter[msg.sender]; 
    
        //увеличиваем счетчик количества закрашенных любым цветом клеток для пользователя
        totalCounterForUser = totalCounterForUser.add(1); 
    
        //обновляем значение общего количества закрашенных любым цветом клеток для пользователя в маппинге
        userToTotalCounter[msg.sender] = totalCounterForUser;
                
        // устанавливаем время закрашивания конкретным цветом в n-ый раз для пользователя
        userToColorToCounterToTimestamp[msg.sender][_color][totalCounterToColorForUser] = now;
    
        // устанавливаем время закрашивания любым цветом в n-ый раз для пользователя за текущий раунд
        userToCounterToTimestamp[msg.sender][totalCounterForUser] = now;
                
        //увеличиваем значение общего количества разукрашиваний данным цветом для всего раунда
        colorToTotalPaintsForRound[currentRound][_color] = colorToTotalPaintsForRound[currentRound][_color].add(1); 
    
        //увеличиваем значение общего количества разукрашиваний любым цветом для всего раунда
        totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(1); 
    
        //устанавливаем значение последнего сыгранного раунда для пользователя равным текущему раунду
        lastPlayedRound[msg.sender] = currentRound;
                
        //с каждым закрашиванием декреминтируем на 1 ед краски
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);
        
        //сохраняем значени поседнего закрашенного пикселя за раунд
        lastPaintedPixelForRound[currentRound] = _pixel;
        
        //ивент - закрашивание пикселя (пиксель, цвет, закрасивший пользователь)
        emit Paint(_pixel, _color, msg.sender, currentRound);    
            
        //проверяем не закрасилось ли все игровое поле данным цветом для розыгрыша банка цвета
        if (colorToPaintedPixelsAmountForRound[currentRound][_color] == 10000) {

            //цвет победивший в текущем раунде
            winnerColorForRound[currentRound] = _color;

            //распределяем банк цвета команде цвета
            _distributeColorBank();                
        }

    }

    //функция распределения ставки
    function _setBanks(uint _color) private {
        
        colorBankToColorForRound[currentRound][_color] = colorBankToColorForRound[currentRound][_color].add(msg.value.mul(40).div(100));

        //40% ставки идет в банк цвета
        colorBankForRound[currentRound] = colorBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //40% ставки идет в банк времени
        timeBankForRound[currentRound] = timeBankForRound[currentRound].add(msg.value.mul(40).div(100));

        //20% ставки идет на пассивные доходы бенефециариев
        dividendsBank = dividendsBank.add(msg.value.mul(20).div(100)); 
    }

    //запросить приз за послений раунд в котором пользователь принимал участие
    function _claimBankPrizeForLastPlayedRound() public {

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
    
    //dont pay attention
    function showPotentialPrizeForColor(uint _color) external view returns (uint) {

        //время завершения сбора команды приза для раунда
        uint end = now;

        //время начала сбора команды приза для раунда
        uint start = now - 24 hours;

        //cчетчик количества закрашиваний
        uint counter;
        
        //счетчик общего количества закрашиваний выигрышным цветом для пользователя за раунд     
        uint total = colorToUserToTotalCounter[_color][msg.sender]; 

         //считаем сколько закрашиваний выигрышным цветом произвел пользователь за последние 24 часа
        for (uint i = total; i > 0; i--) {
            uint timeStamp = userToColorToCounterToTimestamp[msg.sender][_color][i];
            if (timeStamp > start && timeStamp <= end)
                counter = counter.add(1);
        }
        
        uint potentialPrizeForColor = counter.mul(colorBankToColorForRound[currentRound][_color]).div(colorToTotalPaintsForRound[currentRound][_color]);
        
        return potentialPrizeForColor;
    }
    

}