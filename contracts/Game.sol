pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./DividendsDistributor.sol";
import "./TimeBankDistributor.sol";
import "./ColorTeam.sol";
import "./Storage.sol";
import "./PaintsPool.sol";
import "./PaintDiscount.sol";
import "./IColor.sol";
import "./GameStateController.sol";

contract Game is Ownable, TimeBankDistributor, ColorTeam, PaintsPool, PaintDiscount, DividendsDistributor, GameStateController {

    using SafeMath for uint;
    
    //последний раунд в котором пользователь принимал участие (аgit дрес => раунд)
    mapping (address => uint) public lastPlayedRound; 

    //общее количество уникальных пользователей
    uint public uniqueUsers;

    //маппинг на булевое значение о том, что пользователь зарегистрирован в системе (принимал участие в игре)
    mapping (address => bool) public isRegistered;
    
    //ивенты
    event Paint(uint indexed pixelId, uint colorId, address indexed painter, uint indexed round, uint timestamp);
    event ColorBankPlayed(uint indexed round);
   
    //конструктор, задающий изначальные значения переменных
    constructor() public payable { 
        
        maxPaintsInPool = 10000; //10000 in production
        currentRound = 1;
        cbIteration = 1;
        tbIteration = 1;
        
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
    

    function paint(uint[] _pixels, uint _color) external payable isRegisteredUser isLiveGame {

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

        paintsCounter++; //счетчик закрашивания любым цветом
        paintsCounterForColor[_color] ++; //счетчик закрашивания конкретным цветом
        counterToPainter[paintsCounter] = msg.sender; //счетчик закрашивания => пользователь
        counterToPainterForColor[_color][paintsCounterForColor[_color]] = msg.sender; //счетчик закрашивания конкретным цветом => пользователь

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
                
        //увеличиваем значение общего количества разукрашиваний данным цветом для всего раунда
        colorToTotalPaintsForRound[currentRound][_color] = colorToTotalPaintsForRound[currentRound][_color].add(1); 
    
        //увеличиваем значение общего количества разукрашиваний любым цветом для всего раунда
        totalPaintsForRound[currentRound] = totalPaintsForRound[currentRound].add(1); 

        timeBankShare[tbIteration][msg.sender]++;
        colorBankShare[cbIteration][_color][msg.sender]++;
                
        //с каждым закрашиванием декреминтируем на 1 ед краски
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);
        
        //сохраняем значени поседнего закрашенного пикселя за раунд
        lastPaintedPixelForRound[currentRound] = _pixel;
        
        //ивент - закрашивание пикселя (пиксель, цвет, закрасивший пользователь)
        emit Paint(_pixel, _color, msg.sender, currentRound, now);    

        //устанавливаем значение последнего сыгранного раунда для пользователя равным текущему раунду
        lastPlayedRound[msg.sender] = currentRound;
            
        //проверяем не закрасилось ли все игровое поле данным цветом для розыгрыша банка цвета
        if (colorToPaintedPixelsAmountForRound[currentRound][_color] == 10000) {

            //цвет победивший в текущем раунде
            winnerColorForRound[currentRound] = _color;

            //распределяем банк цвета команде цвета
            winnerOfRound[currentRound] = lastPainterForRound[currentRound];        
            painterToCBP[cbIteration][winnerOfRound[currentRound]] += colorBankForRound[currentRound].mul(50).div(100); 
            winnerBankForRound[currentRound] = 2;//разыгранный банк этого раунда = банк цвета (2)
            //50% банка цвета распределится между командой цвета раунда
            colorBankForRound[currentRound] = colorBankForRound[currentRound].mul(50).div(100); 
            timeBankForRound[currentRound + 1] = timeBankForRound[currentRound];//банк времени переносится на следующий раунд
            timeBankForRound[currentRound] = 0;//банк времени в текущем раунде обнуляется      
            emit ColorBankPlayed(currentRound);  
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
    
}