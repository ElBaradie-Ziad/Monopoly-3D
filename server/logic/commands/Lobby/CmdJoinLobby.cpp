#include "CmdJoinLobby.hpp"
#include "MatchManager.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

namespace Monopoly::Lobby {
    void CmdJoinLobby::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        json response, responseServerPush;
        bool joinSuccess = false;
        std::vector<int> otherPlayers;

        try {
            otherPlayers = match->getAllClientID();

            // Join a Match
            match->addPlayer(msg.clientID, msg.data["username"]);
            MatchManager* mm = MatchManager::getInstance();
            mm->addClientToMatch(msg.clientID, msg.data.at("matchID"));

            // Response
            json data = {
                {"mapID", match->getMapID()},
                {"numberTurn", match->getNumberTurn()},
                {"moneyStart", match->getMoneyStart()},
                {"players", match->getPlayersJSON()}
            };
            response = MessageBuilder::buildResponse(msg.mainID, msg.subID, data);

            // Send the Response to other player
            json payload = {
                {"clientID", msg.clientID},
                {"username", msg.data["username"]}
            };
            responseServerPush = MessageBuilder::buildServerPush(Codes::EventType::LOBBY_PLAYER_JOINED, payload);
            
            joinSuccess = true;

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION JOIN LOBBY: " << e.what() << std::endl;

            // Response
            response = MessageBuilder::buildError(msg.mainID, msg.subID, Codes::ErrorCode::IMPOSSIBLE_TO_JOIN);
        }

        // Send Response
        std::vector<int> recipient = {msg.clientID};
        for (IObserver* o : obs) {
            o->update(response, recipient);

            if (joinSuccess && !otherPlayers.empty()) {
                o->update(responseServerPush, otherPlayers);
            }
        }
    }
    
    void CmdJoinLobby::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdJoinLobby cmd;
        cmd.execute(match, msg, obs);
    }
}
