pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Referral {
    
    using SafeMath for uint;
    
    //зарегистрированный пользователь
    mapping (address => bool) public isRegisteredUser;
    
    //пользователь имеет свою реферальную ссылку (аккредитованный для получения дивидендов рефера)
    mapping (address => bool) public hasRefLink;
    
    //маппинг реферала к реферу
    mapping (address => address) public referralToReferrer;
    
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
    
    //функция регистрации пользователя с реферальной ссылкой рефера
    function registerWithRefLink(string _refLink) isValidRefLink(_refLink) external {
        require(isRegisteredUser[msg.sender] != true, "You are already registered");
        bytes32 refLink = toBytes32(_refLink);
        require(refLinkExists[refLink], "Invalid referral link");
        uniqueUsersCount = uniqueUsersCount.add(1);
        newUserToCounter[msg.sender] = uniqueUsersCount;
        address referrer = refLinkToUser[refLink];
        referralToReferrer[msg.sender] = referrer;
        isRegisteredUser[msg.sender] = true;
        hasReferrer[msg.sender] = true;
    }
    
    //функция регистрации пользователя без реферальной ссылки рефера
    function register() external  {
        require(isRegisteredUser[msg.sender] != true, "You are already registered");
        uniqueUsersCount = uniqueUsersCount.add(1);
        newUserToCounter[msg.sender] = uniqueUsersCount;
        isRegisteredUser[msg.sender] = true;
    }
    
    //функция для покупки реферальной ссылки для пользователя (длина в диапазоне от 4 до 8 символов)
    function buyRefLink(string _refLink) isValidRefLink (_refLink) external payable {
        require(msg.value == 0.1 ether, "Setting referral link costs 0.1 ETH");
        require(hasRefLink[msg.sender] == false, "You have already generated your ref link");
        bytes32 refLink = toBytes32(_refLink);
        require(refLinkExists[refLink] != true, "This referral link already exists, try different one");
        hasRefLink[msg.sender] = true;
        userToRefLink[msg.sender] = _refLink;
        refLinkExists[refLink] = true;
        refLinkToUser[refLink] = msg.sender;
    }
    
    //модификатор проверяющий длину реф. ссылки (длина должна быть в диапазоне от 4 до 8 символов)
    modifier isValidRefLink(string _str) {
        require(bytes(_str).length >= 4, "Ref link should be of length [4,8]");
        require(bytes(_str).length <= 8, "Ref link should be of length [4,8]");
        _;
    }
    
    // convert a string less than 32 characters long to bytes32
    function toBytes32(string _string) pure public returns (bytes16) {
        // make sure that the string isn't too long for this function
        // will work but will cut off the any characters past the 32nd character
        bytes16 _stringBytes;
    
        // simplest way to convert 32 character long string
        assembly {
          // load the memory pointer of string with an offset of 32
          // 32 passes over non-core data parts of string such as length of text
          _stringBytes := mload(add(_string, 32))
        }
    
        return _stringBytes;
    }   

}