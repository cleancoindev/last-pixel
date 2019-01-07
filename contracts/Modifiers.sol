pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";
import "./Utils.sol";

contract Modifiers is StorageV1 {
    using SafeMath for uint;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "You don't have admin rights");
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
            bytes32 refLink = Utils.toBytes32(_refLink);
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
    
}