pragma solidity ^0.4.24;
import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Storage.sol";
import "./Roles.sol";
import "./GameStateController.sol";

contract TimeTeam is Storage, GameStateController {

    using SafeMath for uint;
    event TBPDistributed(uint indexed round, uint indexed tbIteration, address winner);

    //функция формирующая команду времени из последних 100 участников любым цветом
    function formTimeTeam() private returns (uint) {
        
        for (uint i = paintsCounter; i > 0; i--) {
            uint teamMembersCounter;
            if (isInTBT[tbIteration][counterToPainter[i]] == false) {
                
                if (paintsCounter > 100) {
                    if (teamMembersCounter >= 100)   
                        break;
                }
            
                else {
                    if (teamMembersCounter >= paintsCounter)
                        break;
                }
                
                tbTeam[tbIteration].push(counterToPainter[i]);
                teamMembersCounter = teamMembersCounter.add(1);
                isInTBT[tbIteration][counterToPainter[i]] = true;
            }
        }
        return tbTeam[tbIteration].length;
    }
    
    function calculateTBP() private {

        uint length = formTimeTeam();
        address painter;
        uint totalPaintsForTeam; 

        for (uint i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            totalPaintsForTeam += timeBankShare[tbIteration][painter];
        }

        for (i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            painterToTBP[tbIteration][painter] = (timeBankShare[tbIteration][painter].mul(timeBankForRound[currentRound])).div(totalPaintsForTeam);
        }

    }

    function distributeTBP() external onlyAdmin isLiveGame {
        require(isTBPTransfered[tbIteration] == false, "Time Bank Prizes already transferred for this tbIteration");
        address painter;
        calculateTBP();
        uint length = tbTeam[tbIteration].length;
        for (uint i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            if(painterToTBP[tbIteration][painter] != 0)
                painter.transfer(painterToTBP[tbIteration][painter]);
        }
        isTBPTransfered[tbIteration] = true;
        emit TBPDistributed(currentRound, tbIteration, winnerOfRound[currentRound]);
        currentRound = currentRound.add(1); //следующий раунд 
        tbIteration = tbIteration.add(1); //инкрементируем итерацию для банка цвета
    }
}

//TODO по прошествию 20 минут распределить банки времени и цвета для этого и след раундов
//написать тесты
//прокси, логика, бд
