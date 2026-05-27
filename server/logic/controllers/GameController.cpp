#include "GameController.hpp"
#include "MatchManager.hpp"
#include "CmdRollDice.hpp"
#include "CmdGetOutJail.hpp"
#include "CmdUseCard.hpp"
#include "CmdBuyProprety.hpp"
#include "CmdBuyHouse.hpp"
#include "CmdEndTurn.hpp"
#include "CmdReadyNextTurn.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"
#include <iostream>
#include <vector>
#include "IMatchState.hpp"

GameController::GameController(std::vector<IObserver*> obs) : IController(obs) {
    handlers.resize(10, nullptr);

    handlers[Codes::SubID::Game::DICE_ROLLED] = &Monopoly::Game::CmdRollDice::run;
    handlers[Codes::SubID::Game::GOT_OUT_OF_JAIL] = &Monopoly::Game::CmdGetOutJail::run;
    handlers[Codes::SubID::Game::USE_CARD] = &Monopoly::Game::CmdUseCard::run;
    handlers[Codes::SubID::Game::PROPERTY_BOUGHT] = &Monopoly::Game::CmdBuyProprety::run;
    handlers[Codes::SubID::Game::HOUSE_BUILT] = &Monopoly::Game::CmdBuyHouse::run;
    handlers[Codes::SubID::Game::END_TURN] = &Monopoly::Game::CmdEndTurn::run;
    handlers[Codes::SubID::Game::READY_NEXT_TURN] = &Monopoly::Game::CmdReadyNextTurn::run;
}

void GameController::handler(const Message& msg) {
    if (msg.subID < 0 || msg.subID >= handlers.size()) {
        std::cerr << "GameyController: SubID hors limites (" << msg.subID << ")\n";
        return;
    }

    commandFunc func = handlers[msg.subID];
    if (func == nullptr) {
    std::cerr << "GameController: no handler for subID " << msg.subID << "\n";
    return;
    }

    MatchManager* mm = MatchManager::getInstance();
    Match* currentMatch = mm->getMatchByClientID(msg.clientID);

    if (currentMatch == nullptr) {
        json errorResponse = MessageBuilder::buildError(
            msg.mainID, msg.subID, Codes::ErrorCode::UNKNOWN_ERROR
        );
        std::vector<int> asker = {msg.clientID};
        for (IObserver* o : obs) {
            o->update(errorResponse, asker);
        }
        return;
    }

    returnExecute returnResult = currentMatch->getState().canExecute(*currentMatch, msg);

    if (returnResult.ok) {
        func(currentMatch, msg, obs);
    } else {
        json errorResponse = MessageBuilder::buildError(
            msg.mainID, msg.subID, returnResult.error
        );
        std::vector<int> asker = {msg.clientID};
        for (IObserver* o : obs) {
            o->update(errorResponse, asker);
        }
    }

}
