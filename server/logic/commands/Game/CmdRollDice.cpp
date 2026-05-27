#include "CmdRollDice.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"
#include <iostream>

namespace Monopoly::Game {

#ifdef TEST_MODE
    std::map<int, std::pair<int,int>> CmdRollDice::forcedDiceMap;
    std::mutex CmdRollDice::diceMtx;
#endif

    void CmdRollDice::execute(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        try {
            // Initialize Random Number Generator
            std::srand(std::time(nullptr));

#ifdef TEST_MODE
            int d1, d2;
            {
                std::lock_guard<std::mutex> lock(diceMtx);
                auto it = forcedDiceMap.find(msg.clientID);
                if (it != forcedDiceMap.end()) {
                    d1 = it->second.first;
                    d2 = it->second.second;
                    printf("[SERVER DEBUG] Forced dice for client %d: %d, %d\n", msg.clientID, d1, d2);
                    forcedDiceMap.erase(it);
                } else {
                    printf("[SERVER DEBUG] No forced dice for client %d, rolling random\n", msg.clientID);
                    d1 = (std::rand() % 6) + 1;
                    d2 = (std::rand() % 6) + 1;
                }
            }
#else
            int d1 = (std::rand() % 6) + 1;
            int d2 = (std::rand() % 6) + 1;
#endif

            int cardID = -1;

            GameState::TurnPhase nextPhase =
                applyConsequences(match, msg.clientID, d1, d2, &cardID);

            match->setTurnPhase(nextPhase);
            match->refreshMatchState();

            json payload = {
                {"clientID", msg.clientID},
                {"dice1", d1},
                {"dice2", d2},
                {"card", cardID}
            };

            std::cout << "[SERVER DEBUG] Player money " << match->getPlayerMoney(msg.clientID) << std::endl;

            json responseServerPush =
                MessageBuilder::buildServerPush(Codes::EventType::DICE_ROLLED, payload);

            std::vector<int> asker = {msg.clientID};
            std::vector<int> allPlayers = match->getAllClientID();

            for (IObserver* o : obs) {
                o->update(responseServerPush, allPlayers);
            }

        } catch (const std::exception& e) {
            std::cout << "EXCEPTION ROLL: " << e.what() << std::endl;

            json errorResponse = MessageBuilder::buildError(
                msg.mainID,
                msg.subID,
                Codes::ErrorCode::CANNOT_ROLL_DICE
            );

            std::vector<int> asker = {msg.clientID};
            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
        }
    }

    void CmdRollDice::run(Match* match, const Message& msg, std::vector<IObserver*> obs) {
        CmdRollDice cmd;
        cmd.execute(match, msg, obs);
    }

    GameState::TurnPhase CmdRollDice::applyConsequences(
        Match* match, int clientID, int d1, int d2, int* outCardID) {

        bool isDouble = (d1 == d2);
        bool wasInJail = match->isPlayerInJail(clientID);

        if (wasInJail) {
            match->incrementTurnsInJail(clientID);

            if (isDouble) {
                match->releasePlayerFromJail(clientID);
            } else {
                if (match->getTurnsInJail(clientID) >= 3) {
                    match->removePlayerMoney(clientID, 50);
                    match->releasePlayerFromJail(clientID);
                } else {
                    *outCardID = 10;
                    match->setRolledDice(clientID, true);
                    return GameState::TurnPhase::WAITING_NEXT_TURN;
                }
            }
        }

        if (isDouble && !wasInJail) {
            match->incrementDoubleCount(clientID);
            match->triggerRollDoubleAbility(clientID);
            if (match->getDoubleCount(clientID) == 3) {
                match->sendPlayerToJail(clientID);
                match->resetDoubleCount(clientID);
                match->setRolledDice(clientID, true);
                return GameState::TurnPhase::WAITING_NEXT_TURN;
            }
        } else if (!isDouble) {
            match->resetDoubleCount(clientID);
        }

        int oldPos = match->getPlayerPosition(clientID);
        int newPos = (oldPos + d1 + d2) % 40;

        match->setLastDiceRoll(d1 + d2);
        match->setPlayerPosition(clientID, newPos);

        // Class abilities activation
        if (newPos < oldPos) {
            match->triggerPassStartAbility(clientID);
        }

        for (const auto& otherPlayer : match->getPlayers()) {
            if (otherPlayer->getId() != clientID && !otherPlayer->getIsEliminated() && otherPlayer->getPosition() == newPos) {
                match->triggerSameTileAbility(clientID, otherPlayer->getId());
            }
        }

        ETileType tileType = match->getETileType(newPos);

        if (tileType == ETileType::CHANCE || tileType == ETileType::COMMUNITY_CHEST) {
            *outCardID = match->randomCard(tileType);
            applyCardEffect(match, clientID, *outCardID);
            if (isDouble) {
                return GameState::TurnPhase::BEFORE_ROLL;
            }
            match->setRolledDice(clientID, true);
            return GameState::TurnPhase::WAITING_NEXT_TURN;
        }

        else if (tileType == ETileType::GO_TO_JAIL) {
            *outCardID = 10;
            match->sendPlayerToJail(clientID);
            match->resetDoubleCount(clientID);
            match->setRolledDice(clientID, true);
            return GameState::TurnPhase::WAITING_NEXT_TURN;
        }

        else if (tileType == ETileType::FREE_PARKING || tileType == ETileType::GO || tileType == ETileType::JAIL) {
            if (isDouble) {
                return GameState::TurnPhase::BEFORE_ROLL;
            }
            match->setRolledDice(clientID, true);
            return GameState::TurnPhase::WAITING_NEXT_TURN;
        }

        else if (tileType == ETileType::TAX) {
            match->removePlayerMoney(clientID, match->getTax(newPos));

            if (isDouble) {
                return GameState::TurnPhase::BEFORE_ROLL;
            }
            match->setRolledDice(clientID, true);
            return GameState::TurnPhase::WAITING_NEXT_TURN;
        }

        else {
            *outCardID = newPos;
            int ownerID = match->getPropertyOwner(newPos);

            if (ownerID == -1) {
                return GameState::TurnPhase::PROPERTY_CHOICE;
            }

            if (ownerID != clientID) {
                int rent = match->calculateRent(newPos);
                match->removePlayerMoney(clientID, rent);
                match->addPlayerMoney(ownerID, rent);
            }

            if (ownerID == clientID /*&& match->playerOwnsFullColorGroup(clientID, newPos)*/) {
                return GameState::TurnPhase::BUILD_CHOICE;
            }
        }

        if (!isDouble || wasInJail) {
            match->setRolledDice(clientID, true);
            return GameState::TurnPhase::WAITING_NEXT_TURN;
        }

        return GameState::TurnPhase::BEFORE_ROLL;
    }

    void CmdRollDice::applyCardEffect(Match* match, int clientID, int cardID) {
        switch (cardID) {
        case 100:
            match->setPlayerPosition(clientID, 0);
            match->triggerPassStartAbility(clientID);
            break;
        case 101:
            match->addPlayerMoney(clientID, 200);
            break;
        case 102:
            match->removePlayerMoney(clientID, 150);
            break;
        case 103:
            match->giveGetOutOfJailCard(clientID, cardID);
            break;
        case 104:
            match->sendPlayerToJail(clientID);
            match->setRolledDice(clientID, true);
            break;
        case 200:
            match->addPlayerMoney(clientID, 100);
            break;
        case 201:
            match->addPlayerMoney(clientID, 100);
            break;
        case 202:
            match->removePlayerMoney(clientID, 50);
            break;
        case 203:
            match->giveGetOutOfJailCard(clientID, cardID);
            break;
        case 204:
            match->removePlayerMoney(clientID, 15);
            break;
        default:
            break;
        }
    }

}