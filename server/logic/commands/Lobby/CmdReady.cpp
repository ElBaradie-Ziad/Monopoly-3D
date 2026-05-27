#include "CmdReady.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"
#include <iostream>

namespace Monopoly::Lobby {
    void CmdReady::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        try {
            int classID = msg.data["classID"];
            match->setPlayerClass(msg.clientID, classID);
            match->setPlayerReady(msg.clientID);

            json payload = {
                {"clientID", msg.clientID},
                {"classID", classID}
            };
            json responseServerPush =
                MessageBuilder::buildServerPush(Codes::EventType::ET_READY, payload);

            std::vector<int> allPlayers = match->getAllClientID();
            for (IObserver* o : obs) {
                o->update(responseServerPush, allPlayers);
            }

        } catch (const std::exception& e) {
            json errorResponse = MessageBuilder::buildError(
                msg.mainID,
                msg.subID,
                Codes::ErrorCode::IMPOSSIBLE_TO_BE_READY
            );
            std::vector<int> asker = {msg.clientID};

            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }

    void CmdReady::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdReady cmd;
        cmd.execute(match, msg, obs);
    }
}