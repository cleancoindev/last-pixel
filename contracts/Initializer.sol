pragma solidity ^0.4.24;
import "./StorageV1.sol";

contract Initializer is StorageV1 {

    //constructor
    function _initializer(address _pixelFactoryDeployed, address _colorDeployed) internal {
    //function _initializer() internal {

        colorInstance = Color(_colorDeployed);
        pixelFactoryInstance = PixelFactory(_pixelFactoryDeployed);
        totalColorsNumber = colorInstance.totalSupply();
        //totalColorsNumber = 8;

        isAdmin[msg.sender] = true;
        maxPaintsInPool = 10000; 
        currentRound = 1;
        cbIteration = 1;
        tbIteration = 1;
        
        for (uint i = 1; i <= totalColorsNumber; i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 0.01 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
            paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
            paintGenToEndTimeForColor[i][currentPaintGenForColor[i] - 1] = now;
            paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
        }
        
    }
}