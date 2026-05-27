#include "CmdGetOutJail.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

namespace Monopoly::Game {
    void CmdGetOutJail::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        try {
            match->removePlayerMoney(msg.clientID, 50);
            match->releasePlayerFromJail(msg.clientID);
            match->setTurnPhase(GameState::TurnPhase::BEFORE_ROLL);
            match->refreshMatchState();

            json payload = {
                {"clientID", msg.clientID}
            };
            json responseServerPush =
                MessageBuilder::buildServerPush(Codes::EventType::GOT_OUT_OF_JAIL, payload);

            std::vector<int> allPlayers = match->getAllClientID();

            for (IObserver* o : obs) {
                o->update(responseServerPush, allPlayers);
            }

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION GET OUT OF JAIL: " << e.what() << std::endl;

            json errorResponse = MessageBuilder::buildError(
                msg.mainID,
                msg.subID,
                Codes::ErrorCode::CANNOT_GET_OUT_JAIL
            );
            std::vector<int> asker = {msg.clientID};

            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }
    
    void CmdGetOutJail::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdGetOutJail cmd;
        cmd.execute(match, msg, obs);
    }
}