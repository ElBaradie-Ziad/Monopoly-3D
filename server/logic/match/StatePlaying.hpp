#pragma once

#include "IMatchState.hpp"
#include "json.hpp"

class StatePlaying : public IMatchState {
private:
    Codes::ErrorCode errorForGameCommand(int subID);

    returnExecute canExecuteJailChoice(int subID);
    returnExecute canExecuteBeforeRoll(int subID);
    returnExecute canExecuteAfterRoll(int subID);
public:
    returnExecute canExecute(const Match& match, const Message& msg);

    //validation
    returnExecute canRollDice(const Match& match, int playerId) const;
    returnExecute canBuyProperty(const Match& match, int playerId, int propertyId) const;
    returnExecute canBuildHouse(const Match& match, int playerId, int propertyId, int totalHouses) const;
    returnExecute canUseCard(const Match& match, int playerId, int cardId, const nlohmann::json& data) const;
    returnExecute canGetOutJail(const Match& match, int playerId, const nlohmann::json& data) const;
    returnExecute canEndTurn(const Match& match, int playerId) const;
    returnExecute canReadyNextTurn(const Match& match, int playerId) const;
};
