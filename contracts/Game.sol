pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./DividendsDistributor.sol";
import "./TimeBankDistributor.sol";
import "./ColorBankDistributor.sol";
import "./RoundDataHolder.sol";
import "./PaintsPool.sol";
import "./PaintDiscount.sol";

interface Color {
    function totalSupply() external view returns (uint);
}

contract Game is Ownable, PaintsPool, PaintDiscount, RoundDataHolder, DividendsDistributor, TimeBankDistributor, ColorBankDistributor {

    using SafeMath for uint;
    
    //последний раунд в котором пользователь принимал участие (адрес => раунд)
    mapping (address => uint) public lastPlayedRound; 

    //инстанс Цвета
    Color color;
    
    //ивенты
    event Paint(uint indexed pixelId, uint indexed colorId, address indexed painter);
   
    //конструктор, задающий изначальные значения переменных
    constructor() public payable { 
        
        color = Color(0x7899946bc29f3ab7443903bcc03e8a38407bb44a); //instance of deployed Color contract
        
        maxPaintsInPool = 100; //10000 in production
        currentRound = 1;
        
        for (uint i = 1; i < color.totalSupply(); i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 100 wei;//0.01 ETH in production
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
    
    //возвращает цвет пикселя в этом раунде
    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }
    
    //функция закрашивания пикселя цветом
    function paint(uint _pixel, uint _color) external payable {
        
        //устанавливаем значения для краски в пуле и цену вызова функции paint
        _fillPaintsPool(_color);
        
        //проверяем есть ли у пользователя скидка за покупку краски данным цветом
        if (hasPaintDiscountForColor[_color][msg.sender] == true ) {
            
            //если да, то обновляем цену вызова функции paint с учетом скидки
            uint discountCallPrice = callPriceForColor[_color].mul(100 - usersPaintDiscountForColor[_color][msg.sender].div(100));
            require(msg.value == discountCallPrice , "Wrong call price...");
        }
            
        else
            require(msg.value == callPriceForColor[_color], "Wrong call price...");
            
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
        paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]].sub(1);
        
        //сохраняем значение отраченных пользователем дляенег на покупку краски данного цвета
        _setMoneySpentByUserForColor(_color);
        
        //сохраняем зачение скидки на покупку краски данного цвета для пользователя
        _setUsersPaintDiscountForColor(_color);
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
    
    //функция устанавливающая адрес задеплоенного контракта NFT Цвет
    function setColorInstanceAddress(address _deployed) external onlyOwner {
        color = Color(_deployed);
    }

}