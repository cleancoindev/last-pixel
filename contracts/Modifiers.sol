pragma solidity ^0.4.24;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./StorageV1.sol";

contract Modifiers is StorageV1 {
    using SafeMath for uint;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "You don't have admin rights");
        _;
    }

    modifier onlyOwner() {
        require(isOwner(), "You dont have owner rights");
        _;
    }

    modifier isLiveGame() {
        require(isGamePaused == false, "Game is paused");
        _;

    }

     //модификатор проверяющий длину реф. ссылки (длина должна быть в диапазоне от 4 до 8 символов)
    modifier isValidRefLink(string _str) {
        require(bytes(_str).length >= 4, "Ref link should be of length [4,8]");
        require(bytes(_str).length <= 8, "Ref link should be of length [4,8]");
        _;
    }

    modifier isRegistered(string _refLink) {
        //если пользователь еще не зарегистрирован
        if (isRegisteredUser[msg.sender] != true) {
            bytes32 refLink = toBytes32(_refLink);
            //если такая реф ссылка действительно существует 
            if (refLinkExists[refLink]) { 
                address referrer = refLinkToUser[refLink];
                referrerToReferrals[referrer].push(msg.sender);
                referralToReferrer[msg.sender] = referrer;
                hasReferrer[msg.sender] = true;
            }
            uniqueUsersCount = uniqueUsersCount.add(1);
            newUserToCounter[msg.sender] = uniqueUsersCount;
            isRegisteredUser[msg.sender] = true;
        }
        _;
    }

    //Internal helper function
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