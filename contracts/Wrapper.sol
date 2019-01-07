pragma solidity ^0.4.24;
import "./Modifiers.sol";

/**
** Wrapper for Transparent Proxy Contract with all the functions' signatures
**/

contract Proxy is Modifiers {

    //ColorTeam.sol
    function distributeCBP() external isLiveGame onlyAdmin {}

    //TimeTeam.sol
    function distributeTBP() external isLiveGame onlyAdmin {}

    //DividendsDistributor.sol
    function claimDividends() external {}
    function approveClaim(uint _claimId) public onlyAdmin() {}

    //GameStateController.sol
    function pauseGame() external onlyAdmin {}
    function resumeGame() external onlyAdmin {}

    //Referral.sol
    function buyRefLink(string _refLink) isValidRefLink (_refLink) external payable {}

    //Roles.sol
    function addAdmin(address _new) external onlyOwner {}
    function removeAdmin(address _admin) external onlyOwner {}
    function renounceAdmin() external onlyAdmin {}

    //Game.sol
    function hardCode() external {}
    function getPixelColor(uint _pixel) external view returns (uint) {}
    function estimateCallPrice(uint[] _pixels, uint _color) public view returns (uint totalCallPrice) {}
    function paint(uint[] _pixels, uint _color, string _refLink) external payable isRegistered(_refLink) isLiveGame {}

    //ERC1538.sol
    function updateContract(address _delegate, string _functionSignatures, string commitMessage) external onlyOwner {}

}