#include "CmdLeaveLobby.hpp"
#include "MatchManager.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

namespace Monopoly::Lobby {
    void CmdLeaveLobby::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        json response;
        json responseServerPush;
        std::vector<int> otherPlayers;

        try {
            MatchManager* mm = MatchManager::getInstance();

            // Remove the player from the match
            match->removePlayer(msg.clientID);
            mm->removeClient(msg.clientID);

            // Success response to leaving player
            response = MessageBuilder::buildResponse(msg.mainID, msg.subID, json::object());

            // Get remaining players after the client leaves
            otherPlayers = match->getAllClientID();

            // If the match is empty, delete it
            if (otherPlayers.empty()) {
                mm->deleteMatch(msg.data.at("matchID"));
            } else {
                json payload = {
                    {"clientID", msg.clientID}
                };

                responseServerPush = MessageBuilder::buildServerPush(
                    Codes::EventType::LOBBY_PLAYER_LEFT,
                    payload
                );
            }

            // Send response to the leaving player
            std::vector<int> asker = {msg.clientID};
            for (IObserver* o : obs) {
                o->update(response, asker);
            }

            // Notify remaining players
            if (!otherPlayers.empty()) {
                for (IObserver* o : obs) {
                    o->update(responseServerPush, otherPlayers);
                }
            }

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION LEAVE LOBBY: " << e.what() << std::endl;

            std::vector<int> asker = {msg.clientID};
            json errorResponse = MessageBuilder::buildError(
                msg.mainID,
                msg.subID,
                Codes::ErrorCode::IMPOSSIBLE_TO_LEAVE
            );

            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }

    void CmdLeaveLobby::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdLeaveLobby cmd;
        cmd.execute(match, msg, obs);
    }
}