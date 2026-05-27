#include "StationTile.hpp"
#include "GameState.hpp"
#include "EColorGroup.hpp"

StationTile::StationTile(const std::string& name) : name(name) {}

int StationTile::getCurrentRent(GameState& game) const {
    if (ownerId == -1) return 0;

    // In Monopoly, rent for stations depends on how many the owner has
    // 1: 25, 2: 50, 3: 100, 4: 200
    // We can check this in GameState
    
    int count = 0;
    for (auto& tile : game.getBoard()) {
        if (tile->getType() == ETileType::RAILROAD) {
            // Need to cast to OwnableTile to check owner
            if (auto ownable = std::dynamic_pointer_cast<IOwnableTile>(tile)) {
                if (ownable->getOwnerId() == ownerId) {
                    count++;
                }
            }
        }
    }

    switch (count) {
        case 1: return 25;
        case 2: return 50;
        case 3: return 100;
        case 4: return 200;
        default: return 0;
    }
}