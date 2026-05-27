#include "UtilityTile.hpp"
#include "GameState.hpp"

UtilityTile::UtilityTile(const std::string& name) : name(name) {}

int UtilityTile::getCurrentRent(GameState& game) const {
    if (ownerId == -1) return 0;

    int count = 0;
    for (auto& tile : game.getBoard()) {
        if (tile->getType() == ETileType::UTILITY) {
            if (auto ownable = std::dynamic_pointer_cast<IOwnableTile>(tile)) {
                if (ownable->getOwnerId() == ownerId) {
                    count++;
                }
            }
        }
    }

    // En Monopoly, le loyer d'un Service est :
    //   x4 la somme des dés si on possède 1 service
    //   x10 la somme des dés si on possède les 2 services
    int diceRoll = game.getLastDiceRoll();
    if (diceRoll <= 0) diceRoll = 7; // fallback au lancer moyen si non initialisé
    return (count == 1) ? 4 * diceRoll : 10 * diceRoll;
}