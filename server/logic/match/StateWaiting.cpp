#include "StateWaiting.hpp"
#include "Match.hpp"
#include "Message.hpp"
#include "GameState.hpp"
#include "IPlayer.hpp"

Codes::ErrorCode StateWaiting::errorForLobbyCommand(int subID) {
    switch (subID) {
        case Codes::SubID::Lobby::CREATE_LOBBY:
            return Codes::ErrorCode::LOBBY_NOT_CREATE;
        case Codes::SubID::Lobby::JOIN_LOBBY:
            return Codes::ErrorCode::IMPOSSIBLE_TO_JOIN;
        case Codes::SubID::Lobby::LEAVE_LOBBY:
            return Codes::ErrorCode::IMPOSSIBLE_TO_LEAVE;
        case Codes::SubID::Lobby::READY:
            return Codes::ErrorCode::IMPOSSIBLE_TO_BE_READY;
        case Codes::SubID::Lobby::START_GAME:
            return Codes::ErrorCode::IMPOSSIBLE_TO_LAUNCH;
        default:
            return Codes::ErrorCode::UNKNOWN_ERROR;
    }
}

Codes::ErrorCode StateWaiting::errorForGameCommand(int subID) {
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

returnExecute StateWaiting::canExecute(const Match& match, const Message& msg) {
    if (msg.mainID == Codes::MainID::LOBBY) {
        switch (msg.subID) {
            case Codes::SubID::Lobby::JOIN_LOBBY:
                return canJoinLobby(match, msg.clientID, msg.data);

            case Codes::SubID::Lobby::LEAVE_LOBBY:
                return canLeaveLobby(match, msg.clientID);

            case Codes::SubID::Lobby::READY:
                return canReadyLobby(match, msg.clientID);

            case Codes::SubID::Lobby::START_GAME:
                return canStartGame(match, msg.clientID);

            default:
                return returnExecute::failure(errorForLobbyCommand(msg.subID));
        }
    }

    if (msg.mainID == Codes::MainID::GAME) {
        return returnExecute::failure(errorForGameCommand(msg.subID));
    }

    return returnExecute::failure(Codes::ErrorCode::UNKNOWN_ERROR);
}

returnExecute StateWaiting::canJoinLobby(const Match& match, int playerId, const nlohmann::json& data) const
{
    if (match.hasPlayer(playerId) || match.isLobbyFull()) {
        return returnExecute::failure(Codes::ErrorCode::IMPOSSIBLE_TO_JOIN);
    }

    return returnExecute::success();
}

returnExecute StateWaiting::canLeaveLobby(const Match& match, int playerId) const
{
    if (!match.hasPlayer(playerId)) {
        return returnExecute::failure(Codes::ErrorCode::IMPOSSIBLE_TO_LEAVE);
    }

    return returnExecute::success();
}

returnExecute StateWaiting::canReadyLobby(const Match& match, int playerId) const
{
    if (!match.hasPlayer(playerId)) {
        return returnExecute::failure(Codes::ErrorCode::IMPOSSIBLE_TO_BE_READY);
    }

    return returnExecute::success();
}

returnExecute StateWaiting::canStartGame(const Match& match, int playerId) const
{
    if (!match.hasPlayer(playerId) ||
        !match.hasMinimumPlayersToStart()) {
        return returnExecute::failure(Codes::ErrorCode::IMPOSSIBLE_TO_LAUNCH);
    }

    return returnExecute::success();
}