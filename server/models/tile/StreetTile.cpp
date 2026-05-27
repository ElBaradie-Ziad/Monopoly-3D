#include "StreetTile.hpp"
#include "GameState.hpp"
#include <stdexcept>

StreetTile::StreetTile(const std::string& name, EColorGroup color, int price, int baseRent, int housePrice, const std::vector<int>& rents, int hotelRent)
    : name(name), color(color), price(price), baseRent(baseRent), housePrice(housePrice), multiRents(rents), hotelRent(hotelRent) {}

int StreetTile::getCurrentRent(GameState& game) const {
    if (ownerId == -1) return 0;

    if (houseCount == 5) return hotelRent;

    if (houseCount == 0) {
        if (game.ownerHasAllPropertyColors(ownerId, color)) {
            return baseRent * 2;
        }
        return baseRent;
    }

    if (houseCount > 0 && houseCount <= 4) {
        return multiRents[houseCount - 1];
    }

    return baseRent;
}

int StreetTile::getHouseCount() const {
    return houseCount;
}

void StreetTile::incrementHouseCount(int totalHouses) {
    if (houseCount < 5) houseCount += totalHouses;
}

void StreetTile::resetHouseCount() {
    houseCount = 0;
}

int StreetTile::getHousePrice() const {
    return housePrice;
}

EColorGroup StreetTile::getColor() const {
    return color;
}