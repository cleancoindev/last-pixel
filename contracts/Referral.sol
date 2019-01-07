pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./StorageV1.sol";
import "./Modifiers.sol";

contract Referral is StorageV1, Modifiers {
    
    using SafeMath for uint;
    
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
    
    // convert a string less than 32 characters long to bytes32
    function toBytes32(string _string) pure internal returns (bytes16) {
        // make sure that the string isn't too long for this function
        // will work but will cut off the any characters past the 32nd character
        bytes16 _stringBytes;
        string memory str = _string;
    
        // simplest way to convert 32 character long string
        assembly {
          // load the memory pointer of string with an offset of 32
          // 32 passes over non-core data parts of string such as length of text
          _stringBytes := mload(add(str, 32))
        }
        return _stringBytes;
    }
}