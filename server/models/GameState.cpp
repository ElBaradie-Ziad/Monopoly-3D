#include "GameState.hpp"
#include "IPlayer.hpp"
#include "StreetTile.hpp"
#include "StationTile.hpp"
#include "UtilityTile.hpp"
#include "StandardTile.hpp"
#include "TaxTile.hpp"
#include "EColorGroup.hpp"
#include <algorithm>
#include <stdexcept>

GameState::GameState() : turnPhase(TurnPhase::TURN_START) {
    board.clear();
    board.reserve(40);

    // 0-9
    board.push_back(std::make_shared<StandardTile>("Départ", ETileType::GO));
    board.push_back(std::make_shared<StreetTile>("Boulevard de Belleville", EColorGroup::BROWN, 60, 2, 50, std::vector<int>{10, 30, 90, 160}, 250));
    board.push_back(std::make_shared<StandardTile>("Caisse de Communauté", ETileType::COMMUNITY_CHEST));
    board.push_back(std::make_shared<StreetTile>("Rue Lecourbe", EColorGroup::BROWN, 60, 4, 50, std::vector<int>{20, 60, 180, 320}, 450));
    board.push_back(std::make_shared<TaxTile>("Impôt sur le revenu", 200));
    board.push_back(std::make_shared<StationTile>("Gare Montparnasse"));
    board.push_back(std::make_shared<StreetTile>("Rue de Vaugirard", EColorGroup::LIGHT_BLUE, 100, 6, 50, std::vector<int>{30, 90, 270, 400}, 550));
    board.push_back(std::make_shared<StandardTile>("Chance", ETileType::CHANCE));
    board.push_back(std::make_shared<StreetTile>("Rue de Courcelles", EColorGroup::LIGHT_BLUE, 100, 6, 50, std::vector<int>{30, 90, 270, 400}, 550));
    board.push_back(std::make_shared<StreetTile>("Avenue de la République", EColorGroup::LIGHT_BLUE, 120, 8, 50, std::vector<int>{40, 100, 300, 450}, 600));

    // 10-19
    board.push_back(std::make_shared<StandardTile>("Prison (visite)", ETileType::JAIL));
    board.push_back(std::make_shared<StreetTile>("Boulevard de la Villette", EColorGroup::PURPLE, 140, 10, 100, std::vector<int>{50, 150, 450, 625}, 750));
    board.push_back(std::make_shared<UtilityTile>("Compagnie de distribution des eaux"));
    board.push_back(std::make_shared<StreetTile>("Avenue de Neuilly", EColorGroup::PURPLE, 140, 10, 100, std::vector<int>{50, 150, 450, 625}, 750));
    board.push_back(std::make_shared<StreetTile>("Rue de Paradis", EColorGroup::PURPLE, 160, 12, 100, std::vector<int>{60, 180, 500, 700}, 900));
    board.push_back(std::make_shared<StationTile>("Gare de Lyon"));
    board.push_back(std::make_shared<StreetTile>("Avenue Mozart", EColorGroup::ORANGE, 180, 14, 100, std::vector<int>{70, 200, 550, 750}, 950));
    board.push_back(std::make_shared<StandardTile>("Caisse de Communauté", ETileType::COMMUNITY_CHEST));
    board.push_back(std::make_shared<StreetTile>("Boulevard Saint-Michel", EColorGroup::ORANGE, 180, 14, 100, std::vector<int>{70, 200, 550, 750}, 950));
    board.push_back(std::make_shared<StreetTile>("Place Pigalle", EColorGroup::ORANGE, 200, 16, 100, std::vector<int>{80, 220, 600, 800}, 1000));

    // 20-29
    board.push_back(std::make_shared<StandardTile>("Parc gratuit", ETileType::FREE_PARKING));
    board.push_back(std::make_shared<StreetTile>("Avenue Matignon", EColorGroup::RED, 220, 18, 150, std::vector<int>{90, 250, 700, 875}, 1050));
    board.push_back(std::make_shared<StandardTile>("Chance", ETileType::CHANCE));
    board.push_back(std::make_shared<StreetTile>("Boulevard Malesherbes", EColorGroup::RED, 220, 18, 150, std::vector<int>{90, 250, 700, 875}, 1050));
    board.push_back(std::make_shared<StreetTile>("Avenue Henri-Martin", EColorGroup::RED, 240, 20, 150, std::vector<int>{100, 300, 750, 950}, 1100));
    board.push_back(std::make_shared<StationTile>("Gare du Nord"));
    board.push_back(std::make_shared<StreetTile>("Faubourg Saint-Honoré", EColorGroup::YELLOW, 260, 22, 150, std::vector<int>{110, 330, 800, 975}, 1150));
    board.push_back(std::make_shared<StreetTile>("Place de la Bourse", EColorGroup::YELLOW, 260, 22, 150, std::vector<int>{110, 330, 800, 975}, 1150));
    board.push_back(std::make_shared<UtilityTile>("Compagnie de distribution d'électricité "));
    board.push_back(std::make_shared<StreetTile>("Rue La Fayette", EColorGroup::YELLOW, 280, 24, 150, std::vector<int>{120, 360, 850, 1025}, 1200));

    // 30-39
    board.push_back(std::make_shared<StandardTile>("Aller en Prison", ETileType::GO_TO_JAIL));
    board.push_back(std::make_shared<StreetTile>("Avenue de Breteuil", EColorGroup::GREEN, 300, 26, 200, std::vector<int>{130, 390, 900, 1100}, 1275));
    board.push_back(std::make_shared<StreetTile>("Avenue Foch", EColorGroup::GREEN, 300, 26, 200, std::vector<int>{130, 390, 900, 1100}, 1275));
    board.push_back(std::make_shared<StandardTile>("Caisse de Communauté", ETileType::COMMUNITY_CHEST));
    board.push_back(std::make_shared<StreetTile>("Boulevard des Capucines", EColorGroup::GREEN, 320, 26, 200, std::vector<int>{130, 390, 900, 1100}, 1275));
    board.push_back(std::make_shared<StationTile>("Gare Saint-Lazare"));
    board.push_back(std::make_shared<StandardTile>("Chance", ETileType::CHANCE));
    board.push_back(std::make_shared<StreetTile>("Avenue des Champs-Élysées", EColorGroup::DARK_BLUE, 320, 28, 200, std::vector<int>{150, 450, 1000, 1200}, 1400));
    board.push_back(std::make_shared<TaxTile>("Taxe de luxe", 150));
    board.push_back(std::make_shared<StreetTile>("Rue de la Paix", EColorGroup::DARK_BLUE, 400, 50, 200, std::vector<int>{200, 600, 1400, 1700}, 2000));

    cards = {100, 101, 102, 103, 104, 200, 201, 202, 203, 204};
}

void GameState::nextTurn() {
    if (players.empty()) return;
    for (auto& p : players) {
        p->setNotReady();
        p->setHasRolledDice(false);
    }
    int currentIdx = -1;
    for (int i = 0; i < (int)players.size(); i++) {
        if (players[i]->getId() == currentPlayerID) {
            currentIdx = i;
            break;
        }
    }
    for (int i = 1; i <= (int)players.size(); i++) {
        int nextIdx = (currentIdx + i) % players.size();
        if (!players[nextIdx]->getIsEliminated()) {
            currentPlayerID = players[nextIdx]->getId();
            return;
        }
    }
    currentPlayerID = -1;
}

void GameState::addPlayer(int clientID, const std::string& name, int initialMoney, int playerClass) {
    auto p = std::make_unique<IPlayer>(clientID, name, initialMoney);
    p->setPlayerClass(playerClass);
    players.emplace_back(std::move(p));
}

void GameState::removePlayer(int clientID) {
    bool wasCurrentPlayer = (clientID == currentPlayerID);
    players.erase(std::remove_if(players.begin(), players.end(), [clientID](const std::unique_ptr<IPlayer>& p) { return p->getId() == clientID; }), players.end());
    if (wasCurrentPlayer) nextTurn();
}

bool GameState::ownerHasAllPropertyColors(int playerId, EColorGroup color) const {
    std::vector<IOwnableTile*> neededEProperties = getPropertiesByColor(color);
    if (neededEProperties.empty()) return false;
    for (auto* property : neededEProperties) {
        if (property->getOwnerId() != playerId) return false;
    }
    return true;
}

void GameState::setLastDiceRoll(int roll) { lastDiceRoll = roll; }

json GameState::toJSON() const {
    json result;
    result["currentPlayerID"] = currentPlayerID;
    json playersJSON = json::array();
    for (const auto& p : players) {
        json playerJSON = {
            {"id", p->getId()},
            {"name", p->getName()},
            {"money", p->getMoney()},
            {"position", p->getPosition()},
            {"inJail", p->checkIfInJail()},
            {"isReady", p->checkIsReady()},
            {"class", p->getPlayerClass()}
        };
        playersJSON.push_back(playerJSON);
    }
    result["players"] = playersJSON;
    return result;
}

// Getters
GameState::TurnPhase GameState::getTurnPhase() const { return turnPhase; }
int GameState::getCurrentPlayerID() const { return currentPlayerID; }
int GameState::getPlayerCount() const { return static_cast<int>(players.size()); }

IPlayer& GameState::getPlayer(int id) {
    for (auto& p : players) { if (p->getId() == id) return *p; }
    throw std::runtime_error("Joueur non trouvé : " + std::to_string(id));
}

const IPlayer& GameState::getPlayer(int id) const {
    for (const auto& p : players) { if (p->getId() == id) return *p; }
    throw std::runtime_error("Joueur non trouvé : " + std::to_string(id));
}

std::vector<std::unique_ptr<IPlayer>>& GameState::getPlayers() { return players; }
const std::vector<std::unique_ptr<IPlayer>>& GameState::getPlayers() const { return players; }

ITile& GameState::getTile(int index) {
    if (index < 0 || index >= (int)board.size()) throw std::out_of_range("Index de case invalide");
    return *board.at(index);
}

const ITile& GameState::getTile(int index) const {
    if (index < 0 || index >= (int)board.size()) throw std::out_of_range("Index de case invalide");
    return *board.at(index);
}

IOwnableTile& GameState::getPropertyByID(int index) {
    auto t = board.at(index);
    if (auto p = std::dynamic_pointer_cast<IOwnableTile>(t)) return *p;
    throw std::runtime_error("La case d'index " + std::to_string(index) + " n'est pas une propriété");
}

const IOwnableTile& GameState::getPropertyByID(int index) const {
    auto t = board.at(index);
    if (auto p = std::dynamic_pointer_cast<IOwnableTile>(t)) return *p;
    throw std::runtime_error("La case d'index " + std::to_string(index) + " n'est pas une propriété");
}

const std::vector<IOwnableTile*> GameState::getAllProperties() const {
    std::vector<IOwnableTile*> result;
    for (auto& t : board) { if (auto p = std::dynamic_pointer_cast<IOwnableTile>(t)) result.push_back(p.get()); }
    return result;
}

int GameState::getLastDiceRoll() const { return lastDiceRoll; }
const std::vector<int>& GameState::getCards() const { return cards; }
std::vector<std::shared_ptr<ITile>>& GameState::getBoard() { return board; }
const std::vector<std::shared_ptr<ITile>>& GameState::getBoard() const { return board; }

// Setters
void GameState::setTurnPhase(TurnPhase phase) { turnPhase = phase; }
void GameState::setCurrentPlayerID(int id) { currentPlayerID = id; }

// Private Helpers
std::vector<IOwnableTile*> GameState::getPropertiesByColor(EColorGroup color) const {
    std::vector<IOwnableTile*> result;
    for (const auto& t : board) {
        if (auto street = std::dynamic_pointer_cast<StreetTile>(t)) {
            if (street->getColor() == color) result.push_back(street.get());
        }
    }
    return result;
}
