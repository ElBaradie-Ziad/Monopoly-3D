#include "CmdBuyHouse.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

namespace Monopoly::Game {
    void CmdBuyHouse::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        try {
            int propertyID = msg.data.at("propertyID");
            int housePrice = match->getHousePrice(propertyID);

            // Apply consequences
            match->removePlayerMoney(msg.clientID, housePrice);
            match->addHouseToProperty(propertyID, msg.data.at("totalHouses"));
            if (match->getPlayerHasRolledDouble(msg.clientID)) {
                match->setTurnPhase(GameState::TurnPhase::BEFORE_ROLL);
            } else {
                match->setTurnPhase(GameState::TurnPhase::WAITING_NEXT_TURN);
            }

            match->refreshMatchState();

            json payload = {
                {"clientID", msg.clientID},
                {"propertyID", propertyID},
                {"totalHouses", msg.data.at("totalHouses")},
                {"newBalance", match->getPlayerMoney(msg.clientID)}
            };
            json responseServerPush =
                MessageBuilder::buildServerPush(Codes::EventType::HOUSE_BUILT, payload);

            std::vector<int> allPlayers = match->getAllClientID();

            for (IObserver* o : obs) {
                o->update(responseServerPush, allPlayers);
            }

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION BUY HOUSE: " << e.what() << std::endl;

            json errorResponse = MessageBuilder::buildError(
                msg.mainID,
                msg.subID,
                Codes::ErrorCode::CANNOT_BUY_HOUSE
            );
            std::vector<int> asker = {msg.clientID};
            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }

    void CmdBuyHouse::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdBuyHouse cmd;
        cmd.execute(match, msg, obs);
    }
}