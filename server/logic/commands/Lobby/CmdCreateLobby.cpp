#include "CmdCreateLobby.hpp"
#include "MatchManager.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

namespace Monopoly::Lobby {
    void CmdCreateLobby::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        json response;

        try {
            MatchManager* mm = MatchManager::getInstance();

            // Create a Match
            int matchID = mm->createMatch(msg.clientID, msg.data["username"], msg.data["mapID"], msg.data["numberTurn"], msg.data["moneyStart"]);
            mm->addClientToMatch(msg.clientID, matchID);

            // Response
            json data = {{"matchID", matchID}};
            response = MessageBuilder::buildResponse(msg.mainID, msg.subID, data);

        } catch(const std::exception& e ) {
            std::cout << "EXCEPTION CREATE LOBBY: " << e.what() << std::endl;

            // Response
            response = MessageBuilder::buildError(msg.mainID, msg.subID, Codes::ErrorCode::LOBBY_NOT_CREATE);
        }

        // Send Response
        std::vector<int> recipient = {msg.clientID};
        for (IObserver* o : obs) {
            o->update(response, recipient);
        }
    }
    
    void CmdCreateLobby::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdCreateLobby cmd;
        cmd.execute(match, msg, obs);
    }
}
