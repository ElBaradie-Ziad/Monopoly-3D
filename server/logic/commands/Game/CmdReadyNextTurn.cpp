#include "CmdReadyNextTurn.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

namespace Monopoly::Game {
    void CmdReadyNextTurn::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        try {
            match->setPlayerReady(msg.clientID);

            if (match->areAllPlayersReady()) {
                match->resetAllPlayersReady();
                match->nextTurn();
                match->beginTurn();
                match->refreshMatchState();

                json payload = {
                    {"currentClientID", match->getCurrentPlayerID()}
                };

                json responseServerPush =
                    MessageBuilder::buildServerPush(Codes::EventType::TURN_CHANGED, payload);

                std::vector<int> allPlayers = match->getAllClientID();
                for (IObserver* o : obs) {
                    o->update(responseServerPush, allPlayers);
                }
            }

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION READY NEXT TURN: " << e.what() << std::endl;

            json errorResponse = MessageBuilder::buildError(
                msg.mainID,
                msg.subID,
                Codes::ErrorCode::CANNOT_READY_NEXT_TURN
            );

            std::vector<int> asker = {msg.clientID};
            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }
    
    void CmdReadyNextTurn::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdReadyNextTurn cmd;
        cmd.execute(match, msg, obs);
    }
}