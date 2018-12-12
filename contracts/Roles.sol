pragma solidity ^0.4.24;
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Roles is Ownable {
    
    mapping(address => bool) public isAdmin;
    
    constructor() internal {
        isAdmin[msg.sender] = true;
    }
    
    function addAdmin(address _new) onlyOwner() {
        isAdmin[_new] = true;
    }
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "You don't have admin privilegues");
        _;
    }
    
    function removeAdmin(address _admin) onlyOwner() {
        isAdmin[_admin] = false;
    }
}