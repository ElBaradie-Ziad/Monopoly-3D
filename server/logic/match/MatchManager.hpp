#pragma once

#include "Match.hpp"
#include <unordered_map>
#include <string>

class MatchManager {
private:
    static MatchManager instance;

    std::unordered_map<int, Match*> matches;
    int nextMatchId;

    std::unordered_map<int, Match*> clientToMatch;

    MatchManager();
    ~MatchManager();

    MatchManager(const MatchManager&) = delete;
    MatchManager& operator=(const MatchManager&) = delete;

    

public:
    static MatchManager* getInstance();

    int createMatch(int ownerID, std::string username, int mapID, int numberTurn, int moneyStart);
    Match* getMatchByMatchID(int matchId);
    Match* getMatchByClientID(int matchId);
    void addClientToMatch(int clientID, int matchID);
    void removeClient(int clientID);
    void deleteMatch(int matchId);
};
