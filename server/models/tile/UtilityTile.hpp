#pragma once

#include "IOwnableTile.hpp"
#include <string>

class UtilityTile : public IOwnableTile {
private:
    std::string name;
    int price = 150;
    int ownerId = -1;

public:
    UtilityTile(const std::string& name);

    std::string getName() const override { return name; }
    ETileType getType() const override { return ETileType::UTILITY; }

    int getOwnerId() const override { return ownerId; }
    void setOwnerId(int id) override { ownerId = id; }
    int getPrice() const override { return price; }
    int getCurrentRent(GameState& game) const override;
};