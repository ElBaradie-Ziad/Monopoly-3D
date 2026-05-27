#pragma once

#include "IMatchState.hpp"
#include "json.hpp"

class StateWaiting : public IMatchState {
private:
  Codes::ErrorCode errorForLobbyCommand(int subID);
  Codes::ErrorCode errorForGameCommand(int subID);

public:
  returnExecute canExecute(const Match &match, const Message &msg);

  // lobby
  returnExecute canJoinLobby(const Match &match, int playerId,
                             const nlohmann::json &data) const;
  returnExecute canLeaveLobby(const Match &match, int playerId) const;
  returnExecute canReadyLobby(const Match &match, int playerId) const;
  returnExecute canStartGame(const Match &match, int playerId) const;
};