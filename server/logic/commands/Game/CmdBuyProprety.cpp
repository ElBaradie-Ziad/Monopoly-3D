#include "CmdBuyProprety.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"
#include <iostream>

namespace Monopoly::Game {
    void CmdBuyProprety::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
    try {
        int propertyID = msg.data.at("propertyID");
        int propertyPrice = match->getPropertyPrice(propertyID);

        match->removePlayerMoney(msg.clientID, propertyPrice);
        match->setPropertyOwner(propertyID, msg.clientID);

        if (match->getPlayerHasRolledDouble(msg.clientID)) {
            match->setTurnPhase(GameState::TurnPhase::PROPERTY_CHOICE);
        } else {
            match->setTurnPhase(GameState::TurnPhase::WAITING_NEXT_TURN);
        }
        
        match->refreshMatchState();

        json payload = {
            {"clientID", msg.clientID},
            {"propertyID", propertyID},
            {"newBalance", match->getPlayerMoney(msg.clientID)}
        };
        json responseServerPush =
            MessageBuilder::buildServerPush(Codes::EventType::PROPERTY_BOUGHT, payload);

        std::vector<int> allPlayers = match->getAllClientID();

        for (IObserver* o : obs) {
            o->update(responseServerPush, allPlayers);
        }

    } catch (const std::exception& e) {
        std::cout << "EXCEPTION BUY PROPERTY: " << e.what() << std::endl;

        json errorResponse = MessageBuilder::buildError(
            msg.mainID,
            msg.subID,
            Codes::ErrorCode::CANNOT_BUY_PROPERTY
        );
        std::vector<int> asker = {msg.clientID};

        for (IObserver* o : obs) {
            o->update(errorResponse, asker);
        }
    }
}

    void CmdBuyProprety::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdBuyProprety cmd;
        cmd.execute(match, msg, obs);
    }
}