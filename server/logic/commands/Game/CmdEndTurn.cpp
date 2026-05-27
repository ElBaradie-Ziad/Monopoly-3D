#include "CmdEndTurn.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"
#include <iostream>

namespace Monopoly::Game {
    void CmdEndTurn::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        try {
            match->setTurnPhase(GameState::TurnPhase::WAITING_NEXT_TURN_READY);
            match->refreshMatchState();

            json payload = {
                {"clientID", msg.clientID}
            };
            json responseServerPush =
                MessageBuilder::buildServerPush(Codes::EventType::END_TURN, payload);

            std::vector<int> allPlayers = match->getAllClientID();
            for (IObserver* o : obs) {
                o->update(responseServerPush, allPlayers);
            }

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION END TURN: " << e.what() << std::endl;

            json errorResponse = MessageBuilder::buildError(
                msg.mainID,
                msg.subID,
                Codes::ErrorCode::CANNOT_END_TURN
            );
            std::vector<int> asker = {msg.clientID};
            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }

    void CmdEndTurn::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdEndTurn cmd;
        cmd.execute(match, msg, obs);
    }
}