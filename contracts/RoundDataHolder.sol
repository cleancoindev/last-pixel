pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract RoundDataHolder {
    
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

    //время начала образования команды банка за раунд (раунд => время)
    mapping(uint => uint) public teamStartedTimeForRound;

    //время завершения команды банка за раунд (раунд => время)
    mapping(uint => uint) public teamEndedTimeForRound;

    /*
    //счетчик общего количества закрашенных конкретным цветом клеток для пользователя за раунд (раунд => цвет => адрес => количество клеток)
    mapping (uint => mapping(uint => mapping (address => uint))) public colorToAddressToTotalCounterForRound; 
    */

    //счетчик общего количества закрашенных конкретным цветом клеток для пользователя (цвет => адрес => количество клеток)
    mapping(uint => mapping (address => uint)) public colorToUserToTotalCounter; 

    /*
    //счетчик общего количества закрашиваний любым цветом для пользователя за раунд (раунд => адрес => количество клеток)                                                                        
    mapping(uint => mapping (address => uint)) public addressToTotalCounterForRound;
    */

    //счетчик общего количества закрашиваний любым цветом для пользователя(адрес => количество клеток)                                                                        
    mapping (address => uint) public userToTotalCounter;

    /*
    //время использования краски определенного цвета в n-ый по счету раз для пользователя за раунд (адрес => цвет краски => счетчик => метка времени)                                                                                      
    mapping (uint => mapping(address => mapping (uint => mapping (uint => uint)))) public addressToColorToCounterToTimestampForRound; 
    */

    //время использования краски определенного цвета в n-ый по счету раз для пользователя за раунд (адрес => цвет краски => счетчик => метка времени)                                                                                      
    mapping(address => mapping (uint => mapping (uint => uint))) public userToColorToCounterToTimestamp;             

    /*
    //время использования краски любого цвета в n-ый по счету раз для пользователя за раунд (адрес => счетчик => метка времени)                                                                    
    mapping(uint=>mapping(address=>mapping(uint=>uint))) public addressToCounterToTimestampForRound; 
    */

    //время использования краски любого цвета в n-ый по счету раз для пользователя(адрес => счетчик => метка времени)                                                                    
    mapping(address => mapping(uint => uint)) public userToCounterToTimestamp; 

    //булевое значение проверяет получил ли пользователь приз банка за раунд (адрес => раунд => булевое значение)                                                                            
    mapping(address => mapping(uint => bool)) public isPrizeDistributedForRound;
    
    //приз банка цвета для пользователя за раунд (раунд => адрес => выигрыш)
    mapping(uint => mapping(address => uint)) public addressToColorBankPrizeForRound; 

    //приз банка времени для пользователя за раунд (раунд => адрес => выигрыш)
    mapping(uint => mapping(address => uint)) public addressToTimeBankPrizeForRound; 

    //победитель раунда (раунд => адрес)
    mapping (uint => address) public winnerOfRound; 

    //банк который был разыгран в раунде (раунд => разыгранный банк) (1 = банк времени, 2 = банк цвета)
    mapping (uint => uint) public winnerBankForRound; 

    //маппинг о том принимал ли участие в каком либо раунде пользователь
    mapping (uint => mapping (address => bool)) public hasTakenPartInRound;

    //последний раунд в котором пользователь принимал участие (адрес => раунд)
    mapping (address => uint) public lastPlayedRound; 

    //текущий раунд
    uint public currentRound;

}