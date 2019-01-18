pragma solidity ^0.4.24;
import "./StorageV1.sol";

contract Helpers is StorageV1 {

    //возвращает цвет пикселя в этом раунде (на данный момент)
    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }

}