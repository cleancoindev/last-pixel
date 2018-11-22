pragma solidity ^0.4.24;
import "node_modules/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Color is ERC721, ERC721Metadata, ERC721Enumerable, Ownable {
    using SafeMath for uint;
    constructor() ERC721Metadata("Color", "CLR") public { //TODO change name and symbol
        super._mint(owner(), counter);
        //generateURI("TRANSPARENT"); //just for hardcoding purposes only. Need to change
        super._setTokenURI(counter, "TRANSPARENT"); 
        colorExists["TRANSPARENT"] = true;
        counter = counter.add(1);
    }
    
    uint public counter = totalSupply();
    mapping (string => uint) colorToId; // цветовая гамма на id цвета
    mapping (string => bool) colorExists; //цветовая гамма на булевое значение
    
    modifier isUniqueColor(string _colorCode) {
        require(colorExists[_colorCode] == false, "Sorry you can't choose existing color");
        _;
    }
    
    function mintColorToMyself(string _colorCode) external payable isUniqueColor(_colorCode) {
        require(msg.value == 1 ether, "Minting costs 1 ETH"); //change to 100 ether on production
        //generateURI(_colorCode); /вызывается микросервисом-оракулом для генерации нового ури
        super._mint(msg.sender, counter);
        super._setTokenURI(counter, _colorCode); //поменять
        colorToId[_colorCode] = counter;
        colorExists[_colorCode] = true;
        counter = counter.add(1);
    }
    
    function mintColorTo(address _to, string _colorCode) external onlyOwner isUniqueColor(_colorCode) {
        super._mint(_to, counter);
        //generateURI(_colorCode); //just for hardcoding purposes only. Need to change
        super._setTokenURI(counter, _colorCode);
        colorExists[_colorCode] = true;
        counter = counter.add(1);
    }
    
    function burnColorFrom(address _owner, uint256 _tokenId) external onlyOwner {
        super._burn(_owner, _tokenId);
    }
    
}

