pragma solidity ^0.4.24;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Storage.sol";
import "./Roles.sol";

contract ColorTeam is Storage, Roles {

    using SafeMath for uint;
    event CBPDistributed(uint indexed round, uint indexed cbIteration, address winner);

    //функция формирующая команду цвета из последних 100 участников выигрывшим цветом
    function formColorTeam(uint _winnerColor) private returns (uint) {
        
        for (uint i = paintsCounterForColor[_winnerColor]; i > 0; i--) {
            uint teamMembersCounter;
            if (isInCBT[cbIteration][counterToPainterForColor[_winnerColor][i]] == false) {
                
                if (paintsCounterForColor[_winnerColor] > 100) {
                    if (teamMembersCounter >= 100)   
                        break;
                }
            
                else {
                    if (teamMembersCounter >= paintsCounterForColor[_winnerColor])
                        break;
                }
                
                cbTeam[cbIteration].push(counterToPainterForColor[_winnerColor][i]);
                teamMembersCounter = teamMembersCounter.add(1);
                isInCBT[cbIteration][counterToPainterForColor[_winnerColor][i]] = true;
            }
        }
        return cbTeam[cbIteration].length;
    }
    
    function calculateCBP(uint _winnerColor) private {

        uint length = formColorTeam(_winnerColor);
        address painter;
        uint totalPaintsForTeam; //засунуть в функцию calculateCBP

        for (uint i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            totalPaintsForTeam += colorBankShare[cbIteration][_winnerColor][painter];
        }

        for (i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            painterToCBP[cbIteration][painter] = (colorBankShare[cbIteration][_winnerColor][painter].mul(colorBankForRound[currentRound])).div(totalPaintsForTeam);
        }

    }

    function distributeCBP() external onlyAdmin {
        require(isCBPTransfered[cbIteration] == false, "Color Bank Prizes already transferred for this cbIteration");
        address painter;
        calculateCBP(winnerColorForRound[currentRound]);
        uint length = cbTeam[cbIteration].length;
        for (uint i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            if(painterToCBP[cbIteration][painter] != 0)
                painter.transfer(painterToCBP[cbIteration][painter]);
        }
        isCBPTransfered[cbIteration] = true;
        emit CBPDistributed(currentRound, cbIteration, winnerOfRound[currentRound]);
        currentRound = currentRound.add(1); //следующий раунд 
        cbIteration = cbIteration.add(1); //инкрементируем итерацию для банка цвета      
    }
}