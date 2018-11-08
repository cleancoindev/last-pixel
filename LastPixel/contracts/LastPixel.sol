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
    mapping (uint256 => uint256) public colorTotalPainted;
    mapping (uint256 => uint256) public colorGeneration;
    mapping (uint256 => uint256) public colorPaintedAmt;
    mapping (uint256 => uint256) public colorPaintPrice;
    uint256[10001] public pixelColors;
    
    uint lastTimeStamp = 0;
    
    uint public timeBank = 0;
    uint public colorBank = 0;
    
    constructor(address _proxyRegistryAddress) public {
        
        masterAddr = msg.sender;
        lastPainter = msg.sender;
        pixelTokenAddr = new PixelToken(_proxyRegistryAddress);
        colorTokenAddr = new ColorToken(_proxyRegistryAddress);
        
    }
    
    function buyPixel() public payable {
        require(pixelTotalSupplied < 10000);
        require(msg.value >= 0.1 ether);
        
        pixelTokenAddr.mintTo(msg.sender);
        pixelTotalSupplied += 1;
        pixelSupplied[pixelTotalSupplied] = true;
        
        // send dividends
        masterAddr.transfer(msg.value);
    }
    
    function buyColor() public payable {
        require(colorTotalSupplied < 8);
        require(msg.value >= 100 ether);
        
        colorTokenAddr.mintTo(msg.sender);
        colorTotalSupplied += 1;
        colorPaintedAmt[colorTotalSupplied] = 0;
        colorGeneration[colorTotalSupplied] = 1;
        colorTotalPainted[colorTotalSupplied] = 0;
        colorPaintPrice[colorTotalSupplied] = 0.01 ether;
        
        // send dividends
        masterAddr.transfer(msg.value);
    }
    
    function paint(uint x, uint y, uint colorId) public payable {
        require(x >= 1 && x <= 100);
        require(y >= 1 && y <= 100);
        require(colorId >= 1 && colorId <= colorTotalSupplied);
        
        // update price
        if (colorTotalPainted[colorId] > 10000 * colorGeneration[colorId]) {
            colorGeneration[colorId] += 1;
            colorPaintPrice[colorId] *= 105;
            colorPaintPrice[colorId] /= 100;
        }

        require(msg.value == colorPaintPrice[colorId]);
        
        // get pixel id from x and y
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
        
        // update banks
        timeBank += msg.value * 2 / 5;
        colorBank += msg.value * 2 / 5;
        
        // update pixel colors
        colorPaintedAmt[pixelColors[pixelId]] -= 1;
        pixelColors[pixelId] = colorId;
        colorPaintedAmt[colorId] += 1;
        colorTotalPainted[colorId] += 1;
        
        // check color winner
        if (colorPaintedAmt[colorId] == 10000) {
            msg.sender.transfer(colorBank);
            for (uint i = 1; i <= 10000; i++) {
                pixelColors[i] = 0;
            }
            for (i = 1; i <= colorTotalSupplied; i++) {
                colorPaintedAmt[i] = 0;
            }
            colorBank = 0;
        }
        
        // check time winner
        if (lastTimeStamp == 0) {
            lastTimeStamp = now;
        } else if (now - lastTimeStamp >= 900) {
            lastPainter.transfer(timeBank);
            timeBank = 0;
        }
        
        lastTimeStamp = now;
        lastPainter = msg.sender;
    }
    
}
