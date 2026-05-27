#pragma once

#include "IOwnableTile.hpp"
#include <string>

class StationTile : public IOwnableTile {
private:
    std::string name;
    int price = 200;
    int ownerId = -1;

public:
    StationTile(const std::string& name);

    std::string getName() const override { return name; }
    ETileType getType() const override { return ETileType::RAILROAD; }

    int getOwnerId() const override { return ownerId; }
    void setOwnerId(int id) override { ownerId = id; }
    int getPrice() const override { return price; }
    int getCurrentRent(GameState& game) const override;
};
