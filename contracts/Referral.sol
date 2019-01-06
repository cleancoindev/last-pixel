pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./StorageV1.sol";
import "./Utils.sol";

contract Referral is StorageV1 {
    
    using SafeMath for uint;
    
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
    
    //функция для покупки реферальной ссылки для пользователя (длина в диапазоне от 4 до 8 символов)
    function buyRefLink(string _refLink) isValidRefLink (_refLink) external payable {
        require(msg.value == 0.1 ether, "Setting referral link costs 0.1 ETH");
        require(hasRefLink[msg.sender] == false, "You have already generated your ref link");
        bytes32 refLink = Utils.toBytes32(_refLink);
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
    

}