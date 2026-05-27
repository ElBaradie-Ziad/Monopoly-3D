#pragma once

#include "EColorGroup.hpp"
#include "IPlayer.hpp"
#include "ITile.hpp"
#include "json.hpp"
#include <memory>
#include <string>
#include <vector>

class IOwnableTile;

using json = nlohmann::json;

class GameState {
public:
  enum class TurnPhase {
    TURN_START,
    JAIL_CHOICE,
    BEFORE_ROLL,
    WAITING_NEXT_TURN,
    PROPERTY_CHOICE,
    BUILD_CHOICE,
    WAITING_NEXT_TURN_READY
  };

private:
  std::vector<std::unique_ptr<IPlayer>> players;
  std::vector<std::shared_ptr<ITile>> board;
  std::vector<int> cards;

  TurnPhase turnPhase;
  int currentPlayerID = -1;
  int lastDiceRoll = 0;

  std::vector<IOwnableTile *> getPropertiesByColor(EColorGroup color) const;

public:
  GameState();
  ~GameState() = default;

  void nextTurn();
  void addPlayer(int clientID, const std::string &name, int initialMoney, int playerClass);
  void removePlayer(int clientID);
  bool ownerHasAllPropertyColors(int playerId, EColorGroup color) const;
  void setLastDiceRoll(int roll);
  json toJSON() const;

  // Getters
  TurnPhase getTurnPhase() const;
  int getCurrentPlayerID() const;
  int getPlayerCount() const;
  IPlayer &getPlayer(int id);
  const IPlayer &getPlayer(int id) const;
  std::vector<std::unique_ptr<IPlayer>> &getPlayers();
  const std::vector<std::unique_ptr<IPlayer>> &getPlayers() const;
  ITile &getTile(int index);
  const ITile &getTile(int index) const;
  IOwnableTile &getPropertyByID(int index);
  const IOwnableTile &getPropertyByID(int index) const;
  const std::vector<IOwnableTile *> getAllProperties() const;
  int getLastDiceRoll() const;
  const std::vector<int> &getCards() const;
  std::vector<std::shared_ptr<ITile>> &getBoard();
  const std::vector<std::shared_ptr<ITile>> &getBoard() const;

  // Setters
  void setTurnPhase(TurnPhase phase);
  void setCurrentPlayerID(int id);
};
