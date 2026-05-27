#include "CmdUseCard.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

namespace Monopoly::Game {

    void CmdUseCard::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        try {
            int cardID = msg.data.at("cardID");

            match->setTurnPhase(GameState::TurnPhase::BEFORE_ROLL);

            routeCardEffect(match, msg.clientID, cardID);
            match->refreshMatchState();

            json payload = {
                {"clientID", msg.clientID},
                {"cardID", cardID},
                {"newBalance", match->getPlayerMoney(msg.clientID)},
                {"newPosition", match->getPlayerPosition(msg.clientID)},
                {"inJail", match->isPlayerInJail(msg.clientID)}
            };
            json responseServerPush =
                MessageBuilder::buildServerPush(Codes::EventType::USE_CARD, payload);

            std::vector<int> allPlayers = match->getAllClientID();
            for (IObserver* o : obs) {
                o->update(responseServerPush, allPlayers);
            }
        } catch (const std::exception &e) {
            std::cout << "EXCEPTION USE CARD: " << e.what() << std::endl;

            json errorResponse = MessageBuilder::buildError(
                msg.mainID, msg.subID, Codes::ErrorCode::CANNOT_USE_CARD);
            std::vector<int> asker = {msg.clientID};
            for (IObserver *o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }

    void CmdUseCard::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdUseCard cmd;
        cmd.execute(match, msg, obs);
    }

    void CmdUseCard::routeCardEffect(Match* match, int clientID, int cardID) {
        switch (cardID) {
        case 203:
        case 103:
            effectGetOutJailFree(match, clientID, cardID);
            break;

        default:
            throw std::runtime_error("UNKNOWN_OR_UNUSABLE_CARD_ID");
        }
    }

    void CmdUseCard::effectGetOutJailFree(Match *match, int clientID, int cardID) {
        match->releasePlayerFromJail(clientID);
        match->removePlayerCard(clientID, cardID);
    }
}