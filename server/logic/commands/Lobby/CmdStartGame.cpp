#include "CmdStartGame.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"
#include "IPlayer.hpp"

namespace Monopoly::Lobby {
    void CmdStartGame::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        json responseServerPush;
        json response = MessageBuilder::buildResponse(msg.mainID, msg.subID, json::object());

        try {
            // Mark the current player as "Ready"
            match->setPlayerReadyToStartGame(msg.clientID);

            // Check if ALL players are ready
            if (match->areAllPlayersReadyToPlay()) {
                // Start the game (update the state inside the Match object)
                match->start();

                match->nextTurn();
                match->beginTurn();

                // Build the broadcast message (Server Push)
                json payload = {
                    {"currentClientID", match->getCurrentPlayerID()}
                };
                // Get all players in the match
                responseServerPush = MessageBuilder::buildServerPush(Codes::EventType::TURN_CHANGED, payload);
                std::vector<int> allPlayers = match->getAllClientID();
                for (IObserver* o : obs) {
                    o->update(responseServerPush, allPlayers);
                }
            }

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION START GAME: " << e.what() << std::endl;

            // If there is an error
            json errorResponse = MessageBuilder::buildError(msg.mainID, msg.subID, Codes::ErrorCode::IMPOSSIBLE_TO_LAUNCH);
            std::vector<int> asker = {msg.clientID};
            
            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }
    
    void CmdStartGame::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdStartGame cmd;
        cmd.execute(match, msg, obs);
    }
}
