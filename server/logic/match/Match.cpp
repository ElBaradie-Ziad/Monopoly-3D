#include "Match.hpp"
#include "IPlayer.hpp"
#include "StreetTile.hpp"
#include "TaxTile.hpp"
#include "StateWaiting.hpp"
#include "StatePlaying.hpp"
#include "GameState.hpp"
#include <algorithm>

#ifdef TEST_MODE
int  Match::forcedCardID  = -1;
bool Match::hasForcedCard = false;
#endif


Match::Match(int matchId, int ownerId, std::string username, int mapID, int numberTurn, int moneyStart)
    : id(matchId), state(std::make_unique<StateWaiting>()), clientOwnerId(ownerId),
    mapID(mapID), numberTurn(numberTurn), moneyStart(moneyStart) {
        gameState.addPlayer(ownerId, username, moneyStart, Codes::PlayerClass::STANDARD);
    }

Match::~Match() {}

void Match::removePlayer(int clientID) {
    bool wasOwner = isOwner(clientID);

    gameState.removePlayer(clientID);

    if (wasOwner) {
        const auto& players = gameState.getPlayers();

        if (!players.empty()) {
            clientOwnerId = players.front()->getId();
        }
    }
}

void Match::setState(std::unique_ptr<IMatchState> newState) {
    state = std::move(newState);
}

IMatchState& Match::getState() const {
    return *state;
}

const GameState& Match::getGameState() const {
    return gameState;
}

void Match::triggerRollDoubleAbility(int clientID) {
    gameState.getPlayer(clientID).onRollDouble();
}

void Match::triggerPassStartAbility(int clientID) {
    gameState.getPlayer(clientID).onPassStart();
}

void Match::triggerSameTileAbility(int clientID, int otherClientID) {
    gameState.getPlayer(clientID).onSameTileAs(gameState.getPlayer(otherClientID));
}

bool Match::isPlayerReady(int clientID) const {
    return gameState.getPlayer(clientID).checkIsReady();
}

GameState::TurnPhase Match::getTurnPhase() const {
    return gameState.getTurnPhase();
}

const std::vector<std::unique_ptr<IPlayer>>& Match::getPlayers() const {
    return gameState.getPlayers();
}

const std::vector<std::shared_ptr<ITile>>& Match::getBoard() const {
    return gameState.getBoard();
}

std::vector<int> Match::getAllClientID() {
    std::vector<int> result;
    const std::vector<std::unique_ptr<IPlayer>>& playerList = gameState.getPlayers();

    for (int i = 0; i < playerList.size(); i++) {
        result.push_back(playerList.at(i)->getId());
    }

    return result;
}

void Match::removePlayerMoney(int clientID, int money) {
    gameState.getPlayer(clientID).removeMoney(money);
}

void Match::setPlayerReady(int clientID) {
    gameState.getPlayer(clientID).setIsReady();
}

void Match::setPlayerReadyToStartGame(int clientID) {
    gameState.getPlayer(clientID).setReadyToStartGame();
}

bool Match::areAllPlayersReady() const {
    const auto& playerList = gameState.getPlayers();
    for (const auto& p : playerList) {
        if (!p->checkIsReady()) {
            return false;
        }
    }

    return true;
}

bool Match::areAllPlayersReadyToPlay() const {
    const auto& playerList = gameState.getPlayers();
    for (const auto& p : playerList) {
        if (!p->checkIsReadyToStartGame()) {
            return false;
        }
    }

    return true;
}

int Match::getOwnerID() const {
    return this->clientOwnerId;
}

void Match::start() {
    if (dynamic_cast<StateWaiting*>(state.get()) == nullptr) {
        return;
    }

    setState(std::make_unique<StatePlaying>());
}

void Match::resetAllPlayersReady() {
    for (auto& p : gameState.getPlayers()) {
        p->setNotReady();
    }
}

void Match::removePlayerCard(int playerId, int cardId) {
    if (!hasPlayer(playerId)) {
        return;
    }

    IPlayer& player = gameState.getPlayer(playerId);
    auto& cards = player.getCards();

    auto it = std::find(cards.begin(), cards.end(), cardId);
    if (it != cards.end()) {
        cards.erase(it);
    }
}

bool Match::addPlayer(int clientID, std::string username) {
    gameState.addPlayer(clientID, username, moneyStart, Codes::PlayerClass::STANDARD);
    return true;
}

void Match::setPlayerClass(int clientID, int classID) {
    gameState.getPlayer(clientID).setPlayerClass(classID);
}

int Match::getCurrentPlayerID() const {
    return gameState.getCurrentPlayerID();
}

bool Match::hasRolledDice(int clientID) const {
    return gameState.getPlayer(clientID).getHasRolledDice();
}

bool Match::isPlayerInJail(int clientID) const {
    return gameState.getPlayer(clientID).checkIfInJail();
}

void Match::releasePlayerFromJail(int clientID) {
    gameState.getPlayer(clientID).freeFromJail();
}

void Match::sendPlayerToJail(int clientID) {
    gameState.getPlayer(clientID).placeInJail();
}

int Match::getDoubleCount(int clientID) const {
    return gameState.getPlayer(clientID).getDoubleCount();    
}

void Match::resetDoubleCount(int clientID) {
    gameState.getPlayer(clientID).resetDoubleCount();
}

void Match::setRolledDice(int clientID, bool state) {
    gameState.getPlayer(clientID).setHasRolledDice(state);

}

void Match::addPlayerMoney(int clientID, int amount) {
    gameState.getPlayer(clientID).addMoney(amount);
}

enum ETileType Match::getETileType(int position) const {
    return gameState.getBoard().at(position)->getType();
}

int Match::calculateRent(int position) {
    auto& tile = gameState.getBoard().at(position);
    
    if (auto ownable = std::dynamic_pointer_cast<IOwnableTile>(tile)) {
        return ownable->getCurrentRent(gameState);
    }

    throw std::runtime_error("Cannot calculate rent for this square");
}

int Match::randomCard(ETileType tileType) {
#ifdef TEST_MODE
    if (hasForcedCard) {
        hasForcedCard = false;
        return forcedCardID;
    }
#endif
    // 32 cartes en monopoly en total
    if (tileType == ETileType::CHANCE) {
        int index = rand() % 5; 
        return gameState.getCards().at(index);
    } else if (tileType == ETileType::COMMUNITY_CHEST) {
        int index = 5 + (rand() % 5);
        return gameState.getCards().at(index);
    } else {
        throw std::runtime_error("Pas une case de tirage de carte valide");
    }
}

void Match::incrementTurnsInJail(int clientID) {
    gameState.getPlayer(clientID).incrementTurnsInJail();
}

void Match::nextTurn() {
    currentTurn++;
    gameState.nextTurn();
}

int Match::getPropertyOwner(int propertyID) const {
    return getProperty(propertyID).getOwnerId();
}

IOwnableTile& Match::getProperty(int propertyID) {
    return gameState.getPropertyByID(propertyID);
}

const IOwnableTile& Match::getProperty(int propertyID) const {
    return gameState.getPropertyByID(propertyID);
}

int Match::getHousePrice(int propertyID) const {
    const auto& tile = getProperty(propertyID);
    if (auto street = dynamic_cast<const StreetTile*>(&tile)) {
        return street->getHousePrice();
    }
    return 0;
}

void Match::addHouseToProperty(int propertyID, int totalHouses) {
    auto& tile = getProperty(propertyID);
    if (auto street = dynamic_cast<StreetTile*>(&tile)) {
        street->incrementHouseCount(totalHouses);
    }
}

int Match::getPropertyPrice(int propertyID) const {
    return getProperty(propertyID).getPrice();
}

void Match::setPropertyOwner(int propertyID, int clientID) {
    getProperty(propertyID).setOwnerId(clientID);
}

int Match::getPlayerMoney(int clientID) const {
    return gameState.getPlayer(clientID).getMoney();
}

// TO FINISH
int Match::getMapID() const {
    return mapID;
}

int Match::getNumberTurn() const {
    return numberTurn;
}

int Match::getMoneyStart() const {
    return moneyStart;
}

json Match::getPlayersJSON() const {
    json data = json::array();

    for (const auto& p : gameState.getPlayers()) {
        data.push_back({
            {"clientID", p->getId()}, 
            {"username", p->getName()},
            {"ready", p->checkIsReady()},
            {"classID", p->getPlayerClass()}
        });
    }

    return data;
}

int Match::getTurnsInJail(int clientID) const {
    return gameState.getPlayer(clientID).getJailTime();
}

int Match::getTax(int position) const {
    auto& tile = gameState.getBoard().at(position);
    if (auto taxTile = std::dynamic_pointer_cast<TaxTile>(tile)) {
        return taxTile->getTax();
    }
    return 0;
}

int Match::getPlayerPosition(int clientID) const {
    return gameState.getPlayer(clientID).getPosition();
}

void Match::setPlayerPosition(int clientID, int position) {
    gameState.getPlayer(clientID).setPosition(position);
}

void Match::incrementDoubleCount(int clientID) {
    gameState.getPlayer(clientID).incrementDoubleCount();
}

void Match::giveGetOutOfJailCard(int clientID, int cardID) {
    gameState.getPlayer(clientID).getCards().push_back(cardID);
}

int Match::getPropertyHouseCount(int propertyID) const {
    const auto& tile = getProperty(propertyID);
    if (auto street = dynamic_cast<const StreetTile*>(&tile)) {
        return street->getHouseCount();
    }
    return 0;
}

void Match::setLastDiceRoll(int roll) {
    gameState.setLastDiceRoll(roll);
}



bool Match::hasPlayer(int playerId) const
{
    const auto& players = gameState.getPlayers();
    return std::any_of(players.begin(), players.end(),
        [playerId](const std::unique_ptr<IPlayer>& p) {
            return p->getId() == playerId;
        });
}

bool Match::isCurrentPlayer(int playerId) const
{
    return getCurrentPlayerID() == playerId;
}

bool Match::isPlayerActive(int playerId) const
{
    if (!hasPlayer(playerId)) {
        return false;
    }

    const IPlayer& player = gameState.getPlayer(playerId);
    return !player.isBankrupt();
}

bool Match::isPlaying() const
{
    return dynamic_cast<StatePlaying*>(state.get()) != nullptr;
}

bool Match::isValidPropertyId(int propertyId) const
{
    if (propertyId < 0) {
        return false;
    }

    const auto& board = gameState.getBoard();
    return propertyId < static_cast<int>(board.size());
}

bool Match::playerOwnsProperty(int playerId, int propertyId) const
{
    if (!hasPlayer(playerId) || !isValidPropertyId(propertyId)) {
        return false;
    }

    const IOwnableTile& property = getProperty(propertyId);
    return property.getOwnerId() == playerId;
}

bool Match::playerOwnsFullColorGroup(int playerId, int propertyId) const
{
    const auto& property = getProperty(propertyId);
    if (auto street = dynamic_cast<const StreetTile*>(&property)) {
        return ownerHasAllPropertyColors(playerId, street->getColor());
    }
    return false;
}

bool Match::canPlayerAfford(int playerId, int amount) const
{
    if (!hasPlayer(playerId)) {
        return false;
    }

    return getPlayerMoney(playerId) >= amount;
}

bool Match::playerHasCard(int playerId, int cardId) const
{
    if (!hasPlayer(playerId)) {
        return false;
    }

    const IPlayer& player = gameState.getPlayer(playerId);
    const auto& cards = player.getCards();
    return std::find(cards.begin(), cards.end(), cardId) != cards.end();
}

bool Match::canPlayerAttemptJailRoll(int playerId) const
{
    if (!hasPlayer(playerId)) {
        return false;
    }

    if (!isPlayerInJail(playerId)) {
        return false;
    }

    return getTurnsInJail(playerId) < 3;
}

bool Match::respectsEvenBuildingRule(int propertyId) const {
    if (!isValidPropertyId(propertyId)) {
        return false;
    }

    const auto& board = gameState.getBoard();
    const StreetTile* targetStreet = dynamic_cast<const StreetTile*>(board.at(propertyId).get());

    if (targetStreet == nullptr) {
        return false;
    }

    EColorGroup color = targetStreet->getColor();
    int targetHouseCount = targetStreet->getHouseCount();

    for (const auto& tile : board) {
        const StreetTile* street = dynamic_cast<const StreetTile*>(tile.get());

        if (street != nullptr && street->getColor() == color) {
            if (street->getHouseCount() < targetHouseCount) {
                return false;
            }
        }
    }

    return true;
}

bool Match::isPlayerOnProperty(int playerId, int propertyId) const {
    if (!hasPlayer(playerId) || !isValidPropertyId(propertyId)) {
        return false;
    }

    return getPlayerPosition(playerId) == propertyId;
}

bool Match::isValidCardId(int cardId) const {
    const auto& cards = gameState.getCards();
    return cardId >= 0 && cardId < static_cast<int>(cards.size());
}

bool Match::isWaiting() const
{
    return dynamic_cast<StateWaiting*>(state.get()) != nullptr;
}

bool Match::isOwner(int playerId) const
{
    return clientOwnerId == playerId;
}
// a changer
bool Match::isLobbyFull() const
{
    return gameState.getPlayers().size() >= 4;
}

bool Match::hasMinimumPlayersToStart() const
{
    return gameState.getPlayers().size() >= 2;
}

void Match::setOwner(int playerId)
{
    clientOwnerId = playerId;
}

//phases

void Match::setTurnPhase(GameState::TurnPhase phase) {
    gameState.setTurnPhase(phase);
}

void Match::beginTurn() {
    int current = getCurrentPlayerID();
    setRolledDice(current, false);
    resetDoubleCount(current);

    if (isPlayerInJail(current)) {
        setTurnPhase(GameState::TurnPhase::JAIL_CHOICE);
    } else {
        setTurnPhase(GameState::TurnPhase::BEFORE_ROLL);
    }
}

bool Match::isGameFinishedCondition() const {
    const auto& players = gameState.getPlayers();

    int activePlayers = 0;
    for (const auto& player : players) {
        if (!player->isBankrupt()) {
            ++activePlayers;
        }
    }

    return activePlayers <= 1;
}

void Match::refreshMatchState() {
    const auto& players = gameState.getPlayers();
    const auto& board = gameState.getBoard();

    for (const auto& player : players) {
        if (player->isBankrupt()) {
            // Give properties back to the bank and remove houses
            for (auto& tile : board) {
                if (auto ownable = std::dynamic_pointer_cast<IOwnableTile>(tile)) {
                    if (ownable->getOwnerId() == player->getId()) {
                        ownable->setOwnerId(-1);
                        if (auto street = std::dynamic_pointer_cast<StreetTile>(ownable)) {
                            street->resetHouseCount();
                        }
                    }
                }
            }
        }
    }

    bool turnsFinished = (numberTurn > 0 && currentTurn >= numberTurn);
    if (isGameFinishedCondition() || turnsFinished) {
        setState(std::make_unique<StateFinished>());
    }
}

bool Match::ownerHasAllPropertyColors(int playerId, EColorGroup color) const {
    return gameState.ownerHasAllPropertyColors(playerId, color);
}

bool Match::getPlayerHasRolledDouble(int clientID) const {
    return getDoubleCount(clientID) > 0;
}
