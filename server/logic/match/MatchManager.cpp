#include "MatchManager.hpp"

MatchManager MatchManager::instance;

MatchManager::MatchManager() : nextMatchId(1) {}

MatchManager::~MatchManager() {
    for (auto& pair : matches)
        delete pair.second;
    matches.clear();
    clientToMatch.clear();
}

MatchManager* MatchManager::getInstance() {
    return &instance;
}

int MatchManager::createMatch(int ownerID, std::string username, int mapID, int numberTurn, int moneyStart) {
    int id = nextMatchId++;
    matches[id] = new Match(id, ownerID, username, mapID, numberTurn, moneyStart);

    return id;
}

Match* MatchManager::getMatchByMatchID(int matchId) {
    auto it = matches.find(matchId);
    if (it != matches.end()) {
        return it->second;
    }
    
    return nullptr; 
}

Match* MatchManager::getMatchByClientID(int clientID) {
    auto it = clientToMatch.find(clientID);

    if (it != clientToMatch.end()) {
        return it->second;
    }

    return nullptr; 
}

void MatchManager::addClientToMatch(int clientID, int matchID) {
    Match* m = getMatchByMatchID(matchID);
    if (m != nullptr) {
        clientToMatch[clientID] = m;
    }
}

void MatchManager::removeClient(int clientID) {
    clientToMatch.erase(clientID);
}

void MatchManager::deleteMatch(int matchId) {
    auto it = matches.find(matchId);
    if (it != matches.end()) {
        delete it->second;
        matches.erase(it);
    }
}
