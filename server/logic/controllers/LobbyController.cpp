#include "LobbyController.hpp"
#include "MatchManager.hpp"
#include "MessageBuilder.hpp"
#include "CmdCreateLobby.hpp"
#include "CmdLeaveLobby.hpp"
#include "CmdJoinLobby.hpp"
#include "CmdStartGame.hpp"
#include "CmdReady.hpp"
#include "Code.hpp"
#include <iostream>
#include "IMatchState.hpp"

LobbyController::LobbyController(std::vector<IObserver*> obs) : IController(obs) {
    handlers.resize(10, nullptr);

    handlers[Codes::SubID::Lobby::CREATE_LOBBY] = &Monopoly::Lobby::CmdCreateLobby::run;
    handlers[Codes::SubID::Lobby::LEAVE_LOBBY]  = &Monopoly::Lobby::CmdLeaveLobby::run;
    handlers[Codes::SubID::Lobby::JOIN_LOBBY]   = &Monopoly::Lobby::CmdJoinLobby::run;
    handlers[Codes::SubID::Lobby::READY]        = &Monopoly::Lobby::CmdReady::run;
    handlers[Codes::SubID::Lobby::START_GAME]   = &Monopoly::Lobby::CmdStartGame::run;
}

void LobbyController::handler(const Message& msg) {
    if (msg.subID < 0 || msg.subID >= (int)handlers.size()) {
        std::cerr << "LobbyController: SubID hors limites (" << msg.subID << ")\n";
        return;
    }

    commandFunc func = handlers[msg.subID];
    if (func == nullptr) {
        std::cerr << "LobbyController: no handler for subID " << msg.subID << "\n";
        return;
    }

    MatchManager* mm = MatchManager::getInstance();

    if (msg.subID == Codes::SubID::Lobby::CREATE_LOBBY) {
        auto check = canCreateLobby(msg);
        if (!check.ok) {
            json errorResponse = MessageBuilder::buildError(msg.mainID, msg.subID, check.error);
            std::vector<int> asker = {msg.clientID};
            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
            return;
        }

        func(nullptr, msg, obs);
        return;
    }

    Match* targetMatch = nullptr;

    if (msg.subID == Codes::SubID::Lobby::JOIN_LOBBY) {
        if (!msg.data.contains("matchID") || !msg.data["matchID"].is_number_integer()) {
            json errorResponse = MessageBuilder::buildError(
                msg.mainID, msg.subID, Codes::ErrorCode::IMPOSSIBLE_TO_JOIN
            );
            std::vector<int> asker = {msg.clientID};
            for (IObserver* o : obs) {
                o->update(errorResponse, asker);
            }
            return;
        }

        targetMatch = mm->getMatchByMatchID(msg.data["matchID"]);
    } else {
        targetMatch = mm->getMatchByClientID(msg.clientID);
    }

    if (targetMatch == nullptr) {
        Codes::ErrorCode err =
            (msg.subID == Codes::SubID::Lobby::JOIN_LOBBY)
                ? Codes::ErrorCode::IMPOSSIBLE_TO_JOIN
                : Codes::ErrorCode::UNKNOWN_ERROR;

        json errorResponse = MessageBuilder::buildError(msg.mainID, msg.subID, err);
        std::vector<int> asker = {msg.clientID};
        for (IObserver* o : obs) {
            o->update(errorResponse, asker);
        }
        return;
    }

    returnExecute result = targetMatch->getState().canExecute(*targetMatch, msg);

    if (result.ok) {
        func(targetMatch, msg, obs);
    } else {
        json errorResponse = MessageBuilder::buildError(msg.mainID, msg.subID, result.error);
        std::vector<int> asker = {msg.clientID};
        for (IObserver* o : obs) {
            o->update(errorResponse, asker);
        }
    }
}

returnExecute LobbyController::canCreateLobby(const Message& msg) const {
    if (msg.mainID != Codes::MainID::LOBBY ||
        msg.subID != Codes::SubID::Lobby::CREATE_LOBBY) {
        return returnExecute::failure(Codes::ErrorCode::LOBBY_NOT_CREATE);
    }

    if (!msg.data.contains("mapID") || !msg.data["mapID"].is_number_integer()) {
        return returnExecute::failure(Codes::ErrorCode::LOBBY_NOT_CREATE);
    }

    if (!msg.data.contains("numberTurn") || !msg.data["numberTurn"].is_number_integer()) {
        return returnExecute::failure(Codes::ErrorCode::LOBBY_NOT_CREATE);
    }

    if (!msg.data.contains("moneyStart") || !msg.data["moneyStart"].is_number_integer()) {
        return returnExecute::failure(Codes::ErrorCode::LOBBY_NOT_CREATE);
    }

    if (!msg.data.contains("username") || !msg.data["username"].is_string()) {
        return returnExecute::failure(Codes::ErrorCode::LOBBY_NOT_CREATE);
    }

    MatchManager* mm = MatchManager::getInstance();
    if (mm->getMatchByClientID(msg.clientID) != nullptr) {
        return returnExecute::failure(Codes::ErrorCode::LOBBY_NOT_CREATE);
    }

    return returnExecute::success();
}
