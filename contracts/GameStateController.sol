pragma solidity ^0.4.24;
import "./Roles.sol";
import "./StorageV1.sol";
import "./Modifiers.sol";

contract GameStateController is StorageV1, Modifiers {

    function pauseGame() external onlyAdmin {
        require (isGamePaused == false, "Game is already paused");
        isGamePaused = true;
    }

    function resumeGame() external onlyAdmin {
        require (isGamePaused == true, "Game is already live");
        isGamePaused = false;
    }
}
