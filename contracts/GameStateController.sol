pragma solidity ^0.4.24;
import "./Roles.sol";
import "./Modifiers.sol";

contract GameStateController is Modifiers {

    function pauseGame() external onlyAdmin {
        require (isGamePaused == false, "Game is already paused");
        isGamePaused = true;
    }

    function resumeGame() external onlyAdmin {
        require (isGamePaused == true, "Game is already live");
        isGamePaused = false;
    }
}
