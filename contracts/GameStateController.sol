pragma solidity ^0.4.24;
import "./Roles.sol";
import "./StorageV1.sol";

contract GameStateController is StorageV1, Roles {

    modifier isLiveGame() {
        require(isGamePaused == false, "Game is paused");
        _;
    }

    function pauseGame() external onlyAdmin {
        require (isGamePaused == false, "Game is already paused");
        isGamePaused = true;
    }

    function resumeGame() external onlyAdmin {
        require (isGamePaused == true, "Game is already live");
        isGamePaused = false;
    }
}
