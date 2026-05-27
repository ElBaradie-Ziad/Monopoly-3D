#pragma once

#include "GameState.hpp"
#include "IMatchState.hpp"
#include "IObserver.hpp"
#include "EColorGroup.hpp"
#include "json.hpp"
#include <memory>
#include <vector>
#include <string>
#include <StateFinished.hpp>

using json = nlohmann::json;

class Match {
private:
    int id;
    std::unique_ptr<IMatchState> state;
    GameState gameState;
    std::vector<IObserver*> observers;
    int clientOwnerId; 
    int mapID;
    int numberTurn;
    int currentTurn = 0;
    int moneyStart;

    IOwnableTile& getProperty(int propertyID);
    const IOwnableTile& getProperty(int propertyID) const ;

public:
    Match(int matchId, int ownerId, std::string username, int mapID, int numberTurn, int moneyStart);
    ~Match();

#ifdef TEST_MODE
    static void setForcedCard(int cardID) {
        forcedCardID    = cardID;
        hasForcedCard   = true;
    }
    static void clearForcedCard() {
        hasForcedCard = false;
    }
private:
    static int  forcedCardID;
    static bool hasForcedCard;
public:
#endif

    // Lobby Actions
    void removePlayer(int clientID);
    std::vector<int> getAllClientID();
    void removePlayerMoney(int clientID, int money);
    void setPlayerReady(int clientID);
    void setPlayerReadyToStartGame(int clinetID);
    void setPlayerClass(int clientID, int classID);
    void start();
    bool addPlayer(int clientID, std::string username);

    // Game Actions
    void releasePlayerFromJail(int clientID);
    void sendPlayerToJail(int clientID);
    void resetDoubleCount(int clientID);
    void addPlayerMoney(int clientID, int money);
    int calculateRent(int position);
    int randomCard(enum ETileType t);
    void setRolledDice(int clientID, bool state);
    void incrementTurnsInJail(int clientID);
    void nextTurn();
    void addHouseToProperty(int propertyID, int totalHouses);
    void resetAllPlayersReady();   
    void giveGetOutOfJailCard(int clientID, int cardID);
    void incrementDoubleCount(int clientID);
    void removePlayerCard(int playerId, int cardId);
    void beginTurn();
    void refreshMatchState();

    // Validation & Helpers
    bool hasPlayer(int playerId) const;
    bool isCurrentPlayer(int playerId) const;
    bool isPlayerActive(int playerId) const;
    bool isPlaying() const;
    bool isValidPropertyId(int propertyId) const;
    bool playerOwnsProperty(int playerId, int propertyId) const;
    bool playerOwnsFullColorGroup(int playerId, int propertyId) const;
    bool canPlayerAfford(int playerId, int amount) const;
    bool playerHasCard(int playerId, int cardId) const;
    bool canPlayerAttemptJailRoll(int playerId) const;
    bool respectsEvenBuildingRule(int propertyId) const;
    bool isPlayerOnProperty(int playerId, int propertyId) const;
    bool isValidCardId(int cardId) const;
    bool isWaiting() const;
    bool isOwner(int playerId) const;
    bool isLobbyFull() const;
    bool hasMinimumPlayersToStart() const;
    bool areAllPlayersReady() const;
    bool areAllPlayersReadyToPlay() const;
    bool hasRolledDice(int clientID) const;
    bool isPlayerInJail(int clientID) const;
    bool isGameFinishedCondition() const;
    bool ownerHasAllPropertyColors(int playerId, EColorGroup color) const;
    bool getPlayerHasRolledDouble(int clientID) const;

    // Getters
    IMatchState& getState() const;
    const GameState& getGameState() const;
    int getOwnerID() const;
    int getCurrentPlayerID() const;
    int getDoubleCount(int clientID) const;
    enum ETileType getETileType(int position) const;
    int getPropertyOwner(int propertyID) const;
    int getHousePrice(int propertyID) const;
    int getPropertyPrice(int propertyID) const;
    int getPlayerMoney(int clientID) const;
    int getPropertyHouseCount(int propertyID) const;
    int getTurnsInJail(int clientID) const;
    int getTax(int position) const;
    int getPlayerPosition(int clientID) const;
    int getMapID() const;
    int getNumberTurn() const;
    int getMoneyStart() const;
    json getPlayersJSON() const;
    void triggerRollDoubleAbility(int clientID);
    void triggerPassStartAbility(int clientID);
    void triggerSameTileAbility(int clientID, int otherClientID);
    bool isPlayerReady(int clientID) const;
    GameState::TurnPhase getTurnPhase() const;
    const std::vector<std::unique_ptr<IPlayer>>& getPlayers() const;
    const std::vector<std::shared_ptr<ITile>>& getBoard() const;

    // Setters
    void setState(std::unique_ptr<IMatchState> newState);
    void setPropertyOwner(int propertyID, int clientID);
    void setPlayerPosition(int clientID, int position);
    void setLastDiceRoll(int roll);
    void setOwner(int playerId);
    void setTurnPhase(GameState::TurnPhase phase);
};
