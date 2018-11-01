pragma solidity ^0.4.24;

import "./PixelToken.sol";
import "./ColorToken.sol";

contract LastPixel {
    
    address public masterAddr;
    address public lastPainter;
    PixelToken public pixelTokenAddr;
    ColorToken public colorTokenAddr;

    uint public colorTotalSupplied = 0;
    uint public pixelTotalSupplied = 0;
    mapping (uint256 => bool) public pixelSupplied;
    mapping (uint256 => uint256) public colorGeneration;
    mapping (uint256 => uint256) public colorPaintedAmt;
    uint256[10001] public pixelColors;
    
    
    uint public timeBank = 0;
    uint public colorBank = 0;
    
    constructor() public {
        
        masterAddr = msg.sender;
        lastPainter = msg.sender;
        pixelTokenAddr = new PixelToken();
        colorTokenAddr = new ColorToken();
        
    }
    
    function buyPixel() public payable {
        require(pixelTotalSupplied < 10000);
        require(msg.value == 0.1 ether);
        
        pixelTokenAddr.mint(msg.sender, pixelTotalSupplied + 1);
        pixelTotalSupplied += 1;
        pixelSupplied[pixelTotalSupplied] = true;
        
        // send dividends
        masterAddr.transfer(msg.value);
    }
    
    function buyColor() public payable {
        
        // 10 for debug
        // 100 in production
        require(msg.value == 10 ether);
        
        colorTokenAddr.mint(msg.sender, colorTotalSupplied + 1);
        colorTotalSupplied += 1;
        colorPaintedAmt[colorTotalSupplied] = 0;
        colorGeneration[colorTotalSupplied] = 1;
        
        // send dividends
        masterAddr.transfer(msg.value);
    }
    
    function paint(uint x, uint y, uint colorId) public payable {
        require(x >= 1 && x <= 100);
        require(y >= 1 && y <= 100);
        require(colorId >= 1 && colorId <= colorTotalSupplied);
        
        // ------------TODO------------
        // exponentially growing price
        require(msg.value == 0.01 ether);
        
        uint pixelId = (x - 1) * 100 + y;
        
        address pixelOwner = masterAddr;
        if (pixelSupplied[pixelId]) {
            pixelOwner = pixelTokenAddr.ownerOf(pixelId);
        }
        address colorOwner = colorTokenAddr.ownerOf(colorId);
        
        // send dividends
        pixelOwner.transfer(msg.value / 20);
        colorOwner.transfer(msg.value / 20);
        masterAddr.transfer(msg.value / 10);
        
        //update banks
        timeBank += msg.value * 2 / 5;
        colorBank += msg.value * 2 / 5;
        
        colorPaintedAmt[pixelColors[pixelId]] -= 1;
        pixelColors[pixelId] = colorId;
        colorPaintedAmt[colorId] += 1;
        
        if (colorPaintedAmt[colorId] == 10000) {
            msg.sender.transfer(colorBank);
            for (uint i = 1; i <= 10000; i++) {
                pixelColors[i] = 0;
            }
            for (i = 1; i <= colorTotalSupplied; i++) {
                colorPaintedAmt[i] = 0;
            }
        }
        
        lastPainter = msg.sender;
        
        //------------TODO------------
        // check time bank
        
    }
    
}
