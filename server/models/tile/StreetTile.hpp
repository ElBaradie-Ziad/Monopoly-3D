#pragma once

#include "IOwnableTile.hpp"
#include "EColorGroup.hpp"
#include <vector>

class StreetTile : public IOwnableTile {
private:
    std::string name;
    int price;
    int baseRent;
    int housePrice;
    int houseCount = 0;
    std::vector<int> multiRents; 
    int hotelRent;
    int ownerId = -1;
    EColorGroup color;

public:
    StreetTile(const std::string& name, EColorGroup color, int price, int baseRent, int housePrice, const std::vector<int>& rents, int hotelRent);

    std::string getName() const override { return name; }
    ETileType getType() const override { return ETileType::PROPERTY; }

    int getOwnerId() const override { return ownerId; }
    void setOwnerId(int id) override { ownerId = id; }
    int getPrice() const override { return price; }
    int getCurrentRent(GameState& game) const override;

    int getHouseCount() const;
    void incrementHouseCount(int totalHouses);
    void resetHouseCount();
    int getHousePrice() const;
    EColorGroup getColor() const;
};
