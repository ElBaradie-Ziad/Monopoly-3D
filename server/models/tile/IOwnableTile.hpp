#pragma once

#include "ITile.hpp"
#include <string>

class GameState;

class IOwnableTile : public ITile {
public: 
    virtual int getOwnerId() const = 0;
    virtual void setOwnerId(int id) = 0;
    virtual int getPrice() const = 0;
    virtual int getCurrentRent(GameState& game) const = 0;
};
