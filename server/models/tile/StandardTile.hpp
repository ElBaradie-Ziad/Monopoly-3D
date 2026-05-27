#pragma once
#include "IBaseTile.hpp"

class StandardTile : public IBaseTile {
public:
    StandardTile(const std::string& name, ETileType type) : IBaseTile(name, type) {}
};
