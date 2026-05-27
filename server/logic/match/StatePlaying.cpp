#include "StatePlaying.hpp"
#include "Match.hpp"
#include "Message.hpp"
#include "Code.hpp"
#include "GameState.hpp"
#include "IPlayer.hpp"
#include "StreetTile.hpp"
#include "IOwnableTile.hpp"

Codes::ErrorCode StatePlaying::errorForGameCommand(int subID) {
    switch (subID) {
        case Codes::SubID::Game::DICE_ROLLED:
            return Codes::ErrorCode::CANNOT_ROLL_DICE;
        case Codes::SubID::Game::GOT_OUT_OF_JAIL:
            return Codes::ErrorCode::CANNOT_GET_OUT_JAIL;
        case Codes::SubID::Game::USE_CARD:
            return Codes::ErrorCode::CANNOT_USE_CARD;
        case Codes::SubID::Game::PROPERTY_BOUGHT:
            return Codes::ErrorCode::CANNOT_BUY_PROPERTY;
        case Codes::SubID::Game::HOUSE_BUILT:
            return Codes::ErrorCode::CANNOT_BUY_HOUSE;
        case Codes::SubID::Game::END_TURN:
            return Codes::ErrorCode::CANNOT_END_TURN;
        case Codes::SubID::Game::READY_NEXT_TURN:
            return Codes::ErrorCode::CANNOT_READY_NEXT_TURN;
        default:
            return Codes::ErrorCode::UNKNOWN_ERROR;
    }
}

returnExecute StatePlaying::canExecute(const Match& match, const Message& msg) {
    if (msg.mainID != Codes::MainID::GAME) {
        return returnExecute::failure(Codes::ErrorCode::UNKNOWN_ERROR);
    }

    switch (msg.subID) {
        case Codes::SubID::Game::DICE_ROLLED:
            return canRollDice(match, msg.clientID);

        case Codes::SubID::Game::GOT_OUT_OF_JAIL:
            return canGetOutJail(match, msg.clientID, msg.data);

        case Codes::SubID::Game::USE_CARD: {
            if (!msg.data.contains("cardID") || !msg.data["cardID"].is_number_integer()) {
                return returnExecute::failure(Codes::ErrorCode::CANNOT_USE_CARD);
            }
            int cardID = msg.data["cardID"];
            return canUseCard(match, msg.clientID, cardID, msg.data);
        }

        case Codes::SubID::Game::PROPERTY_BOUGHT: {
            if (!msg.data.contains("propertyID") || !msg.data["propertyID"].is_number_integer()) {
                return returnExecute::failure(Codes::ErrorCode::CANNOT_BUY_PROPERTY);
            }
            int propertyID = msg.data["propertyID"];
            return canBuyProperty(match, msg.clientID, propertyID);
        }

        case Codes::SubID::Game::HOUSE_BUILT: {
            if (!msg.data.contains("propertyID") || !msg.data["propertyID"].is_number_integer()) {
                return returnExecute::failure(Codes::ErrorCode::CANNOT_BUY_HOUSE);
            }
            int propertyID = msg.data["propertyID"];
            return canBuildHouse(match, msg.clientID, propertyID, msg.data.at("totalHouses"));
        }

        case Codes::SubID::Game::END_TURN:
            return canEndTurn(match, msg.clientID);

        case Codes::SubID::Game::READY_NEXT_TURN:
            return canReadyNextTurn(match, msg.clientID);

        default:
            return returnExecute::failure(Codes::ErrorCode::UNKNOWN_ERROR);
    }
}

returnExecute StatePlaying::canRollDice(const Match& match, int playerId) const {
    if (!match.hasPlayer(playerId) ||
        !match.isPlayerActive(playerId) ||
        !match.isCurrentPlayer(playerId) ||
        match.hasRolledDice(playerId)) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_ROLL_DICE);
    }

    GameState::TurnPhase phase = match.getTurnPhase();
    if (match.isPlayerInJail(playerId)) {
        if (phase != GameState::TurnPhase::JAIL_CHOICE ||
            !match.canPlayerAttemptJailRoll(playerId)) {
            return returnExecute::failure(Codes::ErrorCode::CANNOT_ROLL_DICE);
        }
    } else {
        if (phase != GameState::TurnPhase::BEFORE_ROLL &&
            phase != GameState::TurnPhase::BUILD_CHOICE &&
            phase != GameState::TurnPhase::PROPERTY_CHOICE) {
            return returnExecute::failure(Codes::ErrorCode::CANNOT_ROLL_DICE);
        }
    }

    return returnExecute::success();
}

returnExecute StatePlaying::canBuildHouse(const Match& match, int playerId, int propertyId, int totalHouses) const {
    if (!match.hasPlayer(playerId) ||
        !match.isPlayerActive(playerId) ||
        !match.isCurrentPlayer(playerId) ||
        !match.isValidPropertyId(propertyId) ||
        match.getTurnPhase() != GameState::TurnPhase::BUILD_CHOICE) {

        return returnExecute::failure(Codes::ErrorCode::CANNOT_BUY_HOUSE);
    }

    const auto& board = match.getBoard();
    const StreetTile* street = dynamic_cast<const StreetTile*>(board.at(propertyId).get());

    if (street == nullptr ||
        !match.playerOwnsProperty(playerId, propertyId) ||
        //!match.playerOwnsFullColorGroup(playerId, propertyId) ||
        (street->getHouseCount() + totalHouses) > 5 ||
        //!match.respectsEvenBuildingRule(propertyId) ||
        !match.canPlayerAfford(playerId, street->getHousePrice() * totalHouses)) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_BUY_HOUSE);
    }

    return returnExecute::success();
}

returnExecute StatePlaying::canBuyProperty(const Match& match, int playerId, int propertyId) const {
    if (!match.hasPlayer(playerId) ||
        !match.isPlayerActive(playerId) ||
        !match.isCurrentPlayer(playerId) ||
        !match.isValidPropertyId(propertyId) ||
        !match.isPlayerOnProperty(playerId, propertyId) ||
        match.getTurnPhase() != GameState::TurnPhase::PROPERTY_CHOICE) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_BUY_PROPERTY);
    }

    const auto& board = match.getBoard();
    const IOwnableTile* ownable = dynamic_cast<const IOwnableTile*>(board.at(propertyId).get());
    if (ownable == nullptr || 
        ownable->getOwnerId() != -1 || 
        !match.canPlayerAfford(playerId, ownable->getPrice())) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_BUY_PROPERTY);
    }

    return returnExecute::success();
}

returnExecute StatePlaying::canEndTurn(const Match& match, int playerId) const {
    GameState::TurnPhase phase = match.getTurnPhase();

    if (!match.hasPlayer(playerId) ||
        !match.isPlayerActive(playerId) ||
        !match.isCurrentPlayer(playerId) ||
        phase == GameState::TurnPhase::JAIL_CHOICE) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_END_TURN);
    }

    return returnExecute::success();
}

returnExecute StatePlaying::canGetOutJail(const Match& match, int playerId, const nlohmann::json& data) const {
    if (!match.hasPlayer(playerId) ||
        !match.isPlayerActive(playerId) ||
        !match.isCurrentPlayer(playerId) ||
        !match.isPlayerInJail(playerId) ||
        match.getTurnPhase() != GameState::TurnPhase::JAIL_CHOICE ||
        !match.canPlayerAfford(playerId, 50)) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_GET_OUT_JAIL);
    }

    return returnExecute::success();
}

returnExecute StatePlaying::canReadyNextTurn(const Match& match, int playerId) const {
    if (!match.hasPlayer(playerId) ||
        !match.isPlayerActive(playerId) ||
        match.getTurnPhase() != GameState::TurnPhase::WAITING_NEXT_TURN_READY ||
        match.isPlayerReady(playerId)) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_READY_NEXT_TURN);
    }

    return returnExecute::success();
}

returnExecute StatePlaying::canUseCard(const Match& match, int playerId, int cardId, const nlohmann::json& data) const {
    auto phase = match.getTurnPhase();
    if (!match.hasPlayer(playerId) ||
        !match.isPlayerActive(playerId) ||
        !match.isCurrentPlayer(playerId) ||
        //phase != GameState::TurnPhase::JAIL_CHOICE ||
        !match.isValidCardId(cardId) ||
        !match.playerHasCard(playerId, cardId)) {
        return returnExecute::failure(Codes::ErrorCode::CANNOT_USE_CARD);
    }

    return returnExecute::success();
}
